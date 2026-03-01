---
title: "Java资源解析"
subtitle: "Java资源加载|Java文件资源加载"
description: "Java资源解析"
date: 2025-03-17T22:36:09+08:00
lastmod: 2025-03-17T22:36:09+08:00
draft: false

authors: ["yzx"]
tags: ["Java"]
categories: []
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_1367.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# Java资源解析

## 类路径资源

类路径资源（如：`classpath:resource/xxx` ）常用来加载 jar 包中的资源文件。

```java
// file:/C:/java/out/test/classes/
// java 类的 class 根目录
URL url1 = classLoader.getResource("");
System.out.println(url1);

// 获取所有 java 类加载器资源根目录, "" 等同 "./"
// file:/C:/java/out/test/classes/
// file:/C:/java/out/test/resources/
// file:/C:/java/out/production/classes/
// file:/C:/java/out/production/resources/
Enumeration<URL> urls1 = classLoader.getResources("./");
while (urls1.hasMoreElements()) {
    URL url = urls1.nextElement();
    System.out.println(url);
}

// file:/C:/java/out/test/classes/com/example/demo/util/
// 具体某个 java 类包目录
URL url2 = getClass().getResource("");
System.out.println(url2);
```



## 运行目录文件资源

获取运行 class 外目录或文件资源 （如：`file:./resource.txt` ）

```java
String userDir = System.getProperties().getProperty("user.dir");
System.out.println("user.dir=[" + userDir + "]");
System.out.println("=========");

// C:\java\res.txt
// user.dir 目录为根目录
URL url = new URL("file:res.txt");
URI uri = new URI(url.toString().replace(" ", "%20"));
File file = new File(uri.getSchemeSpecificPart());
System.out.println(file.getAbsolutePath());
```

## 资源解析工具类

```java
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Stream;

public class ResourceUtils {

    private static final Logger log = LoggerFactory.getLogger(ResourceUtils.class);


    private static final String CLASSPATH_URL_PREFIX = "classpath:";
    private static final String FILE_URL_PREFIX = "file:";

    public static URL getResourceUrl(String location, ClassLoader classLoader) {
        if (location.startsWith(FILE_URL_PREFIX)) {
            try {
                return new URL(location);
            } catch (MalformedURLException ex) {
                return resolveClassPathUrl(location, classLoader, null);
            }
        } else if (location.startsWith(CLASSPATH_URL_PREFIX)) {
            return resolveClassPathUrl(location.substring(CLASSPATH_URL_PREFIX.length()), classLoader, null);
        } else {
            return resolveClassPathUrl(location, classLoader, null);
        }
    }

    public static String readResourceContentString(InputStream is) throws IOException {
        try (BufferedInputStream bis = new BufferedInputStream(is)) {
            byte[] buffer = new byte[2048];
            int len;
            ByteArrayOutputStream bos = new ByteArrayOutputStream(2048);
            while ((len = bis.read(buffer)) != -1) {
                bos.write(buffer, 0, len);
            }
            bos.flush();
            byte[] array = bos.toByteArray();
            return new String(array, StandardCharsets.UTF_8);
        }
    }

    public static InputStream getResourceAsStream(String location, ClassLoader classLoader) throws IOException {
        URL url = getResourceUrl(location, classLoader);
        if (url == null) {
            throw new FileNotFoundException(location);
        }
        URLConnection con = url.openConnection();
        con.setUseCaches(con.getClass().getSimpleName().startsWith("JNLP"));
        try {
            return con.getInputStream();
        } catch (IOException ex) {
            // Close the HTTP connection (if applicable).
            if (con instanceof HttpURLConnection) {
                ((HttpURLConnection) con).disconnect();
            }
            throw ex;
        }
    }

    public static URL resolveClassPathUrl(String path, ClassLoader classLoader, Class<?> clazz) {
        String originPath = path;
        if (path.startsWith("/")) {
            path = path.substring(1);
        }
        try {
            if (clazz != null) {
                return clazz.getResource(path);
            } else if (classLoader != null) {
                return classLoader.getResource(path);
            } else {
                return ClassLoader.getSystemResource(path);
            }
        } catch (IllegalArgumentException ex) {
            log.warn("资源 [{}] 不存在", originPath, ex);
            return null;
        }
    }

    public static InputStream getClassPathInputStream(String path, ClassLoader classLoader, Class<?> clazz) throws IOException {
        InputStream is;
        if (clazz != null) {
            is = clazz.getResourceAsStream(path);
        } else if (classLoader != null) {
            is = classLoader.getResourceAsStream(path);
        } else {
            is = ClassLoader.getSystemResourceAsStream(path);
        }
        if (is == null) {
            log.warn("资源 [{}] 不存在", path);
            throw new FileNotFoundException("资源 [" + path + "] 不存在");
        }
        return is;
    }

    public static File[] resourcePattern(String location, ClassLoader classLoader) {
        String directoryPath = location.substring(0, location.indexOf("*/"));
        String fileName = location.substring(location.lastIndexOf("/") + 1);
        log.info("pattern dir [{}] fileName [{}]", directoryPath, fileName);
        URL url = getResourceUrl(directoryPath, classLoader);
        if (null == url) {
            return new File[0];
        }
        File dirFile;
        try {
            dirFile = new File(new URI(url.toString().replace(" ", "%20")).getSchemeSpecificPart());
        } catch (URISyntaxException e) {
            dirFile = new File(url.getFile());
        }
        File[] dirFiles = dirFile.listFiles(File::isDirectory);
        if (null != dirFiles && dirFiles.length > 0) {
            return Arrays.stream(dirFiles)
                    .map(f -> f.listFiles((dir, name) -> name.equals(fileName)))
                    .filter(Objects::nonNull)
                    .flatMap((Function<File[], Stream<File>>) Arrays::stream)
                    .toArray(File[]::new);
        }
        return new File[0];
    }

    public static File getResourceFile(String location, ClassLoader classLoader) {
        URL url = getResourceUrl(location, classLoader);
        if (null == url) {
            return null;
        } else {
            URI uri = null;
            try {
                uri = new URI(url.toString().replace(" ", "%20"));
            } catch (URISyntaxException e) {
                throw new IllegalArgumentException(e);
            }
            return new File(uri.getSchemeSpecificPart());
        }
    }

}
```

