---
title: "Spring Boot 自定义类加载器"
subtitle: "Spring Boot 自定义类加载器|Spring Boot 修改bean定义"
description: "Spring Boot 自定义类加载器|Spring Boot 修改bean定义"
date: 2025-05-19T23:36:09+08:00
lastmod: 2025-05-19T2336:09+08:00
draft: false

authors: ["yzx"]
tags: ["Spring Boot", "Java"]
categories: ["Spring Boot", "Java"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_2301.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# Spring Boot 自定义类加载器|调整 Bean 定义

## 自定义类加载器

### 创建自定义类加载器

定义可以加载自定义外部目录中 jar 包的类加载器

```java
import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.stereotype.Controller;
import org.springframework.stereotype.Repository;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.RestController;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.lang.annotation.Annotation;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLClassLoader;
import java.net.URLConnection;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;

public class CustomJarClassLoader extends URLClassLoader {

    private static final Logger log = LoggerFactory.getLogger(CustomJarClassLoader.class);

    private final URL[] urls;

    public CustomJarClassLoader(URL[] urls, ClassLoader parent) {
        super(urls, parent);
        this.urls = urls;
    }

    public void addJar(String jarPath) throws MalformedURLException {
        addURL(new File(jarPath).toURI().toURL());
    }

    public void fileSpringClass() {
        Map<String, List<String>> jarMap = parseClassName();
        Map<String, List<Class<?>>> clazzMap = new HashMap<>(4);

        for (Map.Entry<String, List<String>> et : jarMap.entrySet()) {
            String key = et.getKey();
            List<String> classNameList = et.getValue();
            List<Class<?>> clazzList = new ArrayList<>(10);
            clazzMap.put(key, clazzList);
            try {
                for (String clazzName : classNameList) {
                    Class<?> clazz = loadClass(clazzName);
                    Annotation[] declaredAnnotations = clazz.getDeclaredAnnotations();
                    if (0 == declaredAnnotations.length) {
                        continue;
                    }
                    if (clazz.isAnnotationPresent(Component.class) ||
                        clazz.isAnnotationPresent(Service.class) ||
                        clazz.isAnnotationPresent(Repository.class) ||
                        clazz.isAnnotationPresent(RestController.class) ||
                        clazz.isAnnotationPresent(Controller.class)) {
                        clazzList.add(clazz);
                    }
                }
            } catch (ClassNotFoundException e) {
                log.error("解析类异常 [{}]", key, e);
            }
        }
    }

    public Map<String, List<String>> parseClassName() {
        if (null == urls) {
            return Collections.emptyMap();
        }
        Map<String, List<String>> jarClassMap = new HashMap<>(4);
        for (URL url : urls) {
            List<String> classNames = parseJar(url);
            if (!classNames.isEmpty()) {
                jarClassMap.put(url.getFile(), classNames);
            }
        }
        return jarClassMap;
    }

    public List<String> parseJar(URL url) {
        List<String> classNames = new ArrayList<>(10);
        try (JarFile jar = new JarFile(url.getFile())) {
            Enumeration<JarEntry> entries = jar.entries();
            while (entries.hasMoreElements()) {
                JarEntry entry = entries.nextElement();
                String entryName = entry.getName();
                if (entryName.endsWith(".class")) {
                    String className = entryName.replace("/", ".").substring(0, entryName.length() - 6);
                    classNames.add(className);
                }
            }
        } catch (IOException e) {
            log.error("解析 jar 包 [{}] 异常", url, e);
        }
        return classNames;
    }


    public static void main(String[] args) throws MalformedURLException {
        String jarStr = "D:/java-demo/build/libs/java-demo-1.0-SNAPSHOT.jar";
        File jarFile = new File(jarStr);
        URL url = jarFile.toURI().toURL();

        CustomJarClassLoader loader = new CustomJarClassLoader(new URL[]{url}, CustomJarClassLoader.class.getClassLoader());

        try (JarFile jar = new JarFile(url.getFile())) {
            Enumeration<JarEntry> entries = jar.entries();
            while (entries.hasMoreElements()) {
                JarEntry entry = entries.nextElement();
                String entryName = entry.getName();
                if (entryName.endsWith(".class")) {
                    String className = entryName.replace("/", ".").substring(0, entryName.length() - 6);
                    System.out.println(entryName + " -> " + className);

                    Class<?> clazz = loader.loadClass(className);
                    System.out.println(clazz);
                }
            }
        } catch (IOException | ClassNotFoundException e) {
            log.error("解析 jar 包 [{}] 异常", url, e);
        }
    }

    public static void main2(String[] args) throws Exception {
        // 使用示例
        URL url = new File("D:/java-demo/build/libs/loader-test.jar").toURI().toURL();
        CustomJarClassLoader loader = new CustomJarClassLoader(new URL[]{url}, CustomJarClassLoader.class.getClassLoader());
        loader.addJar("/path/to/plugin.jar");
        Class<?> clazz = loader.loadClass("com.plugin.MyBean");

        Enumeration<URL> resources = loader.getResources("META-INF/plugins.factories");
        while (resources.hasMoreElements()) {
            URL el = resources.nextElement();
            URLConnection urlConnection = el.openConnection();
            InputStream inputStream = urlConnection.getInputStream();
            IOUtils.readLines(inputStream, StandardCharsets.UTF_8).forEach(System.out::println);
        }
    }

}
```

### 使用自定义类加载器

主要机制就是在 Spring Boot 启动时替换 `Thread.currentThread().getContextClassLoader()`

```java
ClassLoader originClassLoader = Thread.currentThread().getContextClassLoader();
ClassLoader customClassLoader = new CustomJarClassLoader(urls, originClassLoader);
Thread.currentThread().setContextClassLoader(customClassLoader);
```

Spring Boot 启动时替换为自定义类加载器

```java
import com.example.demo.loader.CustomJarClassLoader;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.boot.logging.DeferredLog;
import org.springframework.core.Ordered;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.PropertySource;
import sun.misc.Unsafe;

import java.io.File;
import java.lang.reflect.Field;
import java.net.URL;
import java.util.Iterator;

public class CustomLoaderEnvironmentPostProcessor implements EnvironmentPostProcessor, Ordered {

    private final DeferredLog log = new DeferredLog();

    private ClassLoader originClassLoader;

    private ClassLoader customClassLoader;

    /**
        // Since Spring Boot 2.4
        private final Log log;
        public CustomLoaderEnvironmentPostProcessor(DeferredLogFactory logFactory) {
            log = logFactory.getLog(CustomLoaderEnvironmentPostProcessor.class);
        }
    */

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        Iterator<PropertySource<?>> it = environment.getPropertySources().iterator();
        boolean notLoadApplication = true;
        while (it.hasNext()) {
            PropertySource<?> source = it.next();
            String name = source.getName();
            if (name.contains("application.yml") || name.contains("application.properties")) {
                notLoadApplication = false;
                break;
            }
        }
        if (notLoadApplication) {
            return;
        }
        // 日志输出，配置文件加载是日志还没初始化，无法打印日志
        application.addInitializers(ctx -> log.replayTo(CustomLoaderEnvironmentPostProcessor.class));
        log.info("custom loader environment post processor started");
        String classDir = environment.getProperty("custom.loader.classDir", String.class, "extendClassDir");
        String jarDir = environment.getProperty("custom.loader.jarDir", String.class, "extendJarDir");
        log.info("custom loader class dir [" + classDir + "] jar dir [" + jarDir + "]");
        URL[] urls = null;
        try {
            File jarDirFile = new File(jarDir);
            if (jarDirFile.exists() && jarDirFile.isDirectory()) {
                File[] jarFiles = jarDirFile.listFiles((d, name) -> name.endsWith(".jar"));
                if (jarFiles != null && jarFiles.length > 0) {
                    urls = new URL[jarFiles.length];
                    for (int i = 0; i < jarFiles.length; i++) {
                        urls[i] = jarFiles[i].toURI().toURL();
                    }
                }
            }
        } catch (Exception e) {
            log.error("custom loader scan jar file failed [" + jarDir + "]", e);
        }
        if (null != urls) {
            originClassLoader = Thread.currentThread().getContextClassLoader();
            customClassLoader = new CustomJarClassLoader(urls, originClassLoader);
            log.info("origin ClassLoader [" + originClassLoader + "] customClassLoader [" + customClassLoader + "]");
            disableReflectionWarning();
            Thread.currentThread().setContextClassLoader(customClassLoader);
        }
    }

    /**
     * 避免反射异常提示
     * WARNING: An illegal reflective access operation has occurred
     * WARNING: Illegal reflective access by org.springframework.cglib.core.ReflectUtils (file:/C:/Users/Administrator/.gradle/caches/modules-2/files-2.1/org.springframework/spring-core/5.2.15.RELEASE/7166224f67f657582f61cec48ab9ece7904b5c87/spring-core-5.2.15.RELEASE.jar) to method java.lang.ClassLoader.defineClass(java.lang.String,byte[],int,int,java.security.ProtectionDomain)
     * WARNING: Please consider reporting this to the maintainers of org.springframework.cglib.core.ReflectUtils
     * WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations
     * WARNING: All illegal access operations will be denied in a future release
     */
    @SuppressWarnings("uncheck")
    public void disableReflectionWarning() {
        try {
            Field theUnsafe = Unsafe.class.getDeclaredField("theUnsafe");
            theUnsafe.setAccessible(true);
            Unsafe unsafe = (Unsafe) theUnsafe.get(null);
            Class<?> cls = Class.forName("jdk.internal.module.IllegalAccessLogger");
            Field logger = cls.getDeclaredField("logger");
            unsafe.putObjectVolatile(cls, unsafe.staticFieldOffset(logger), null);
        } catch (Exception e) {
            // ignore
        }
    }

    @Override
    public int getOrder() {
        return Ordered.LOWEST_PRECEDENCE;
    }

}
```

### 加载配置

添加 ` META-INF/spring.factories` 启动配置

```properties
org.springframework.boot.env.EnvironmentPostProcessor=com.example.CustomLoaderEnvironmentPostProcessor
```

## 调整 Bean 定义

Bean 定义加载完成后调整 Bean 定义

- `BeanFactoryPostProcessor`：在 bean 实例化前调整 bean 定义元数据
- `BeanDefinitionRegistryPostProcessor`：在 bean 实例化前可以调整 bean 定义元数据，还可以添加新的 bean 定义
- `BeanPostProcessor`：在 bean 示例化前后调整 bean 实例数据

```java
import com.example.demo.bean.SayServiceImpl;
import com.example.demo.bean.SayServiceImpl2;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.BeansException;
import org.springframework.beans.factory.config.BeanDefinition;
import org.springframework.beans.factory.config.ConfigurableListableBeanFactory;
import org.springframework.beans.factory.support.BeanDefinitionRegistry;
import org.springframework.beans.factory.support.BeanDefinitionRegistryPostProcessor;
import org.springframework.core.Ordered;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class LoaderBeanDefinitionRegistryPostProcessor implements BeanDefinitionRegistryPostProcessor, Ordered {

    private static final Logger log = LoggerFactory.getLogger(LoaderBeanDefinitionRegistryPostProcessor.class);

    @Override
    public void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry) throws BeansException {
        log.info("postProcessBeanDefinitionRegistry");
        // 添加新的 bean 定义
    }

    @Override
    public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) throws BeansException {
        String[] beanDefinitionNames = beanFactory.getBeanDefinitionNames();
        log.info("postProcessBeanFactory bean definition count [{}]", beanDefinitionNames.length);
        // 修改现有 bean 定义元数据
        for (String beanName : beanDefinitionNames) {
            BeanDefinition def = beanFactory.getBeanDefinition(beanName);
            String beanClassName = def.getBeanClassName();
            if (!StringUtils.isEmpty(beanClassName) && SayServiceImpl.class.getName().equals(beanClassName)) {
                def.setBeanClassName(SayServiceImpl2.class.getName());
            }
        }
		// 后续自定义业务处理逻辑
    }

    @Override
    public int getOrder() {
        return Ordered.LOWEST_PRECEDENCE;
    }

}
```