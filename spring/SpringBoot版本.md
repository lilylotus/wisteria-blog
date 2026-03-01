---
title: "Spring Boot 版本列表"
subtitle: "Spring Boot 版本列表"
description: "Spring Boot 版本列表"
date: 2025-10-21T22:16:09+08:00
lastmod: 2025-10-21T22:16:09+08:00
draft: false

authors: ["yzx"]
tags: ["Spring Boot"]
categories: ["Spring Boot"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_2488.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# Spring Boot 版本列表

## Spring Boot 版本

[Spring Boot 最新版本官网地址](https://spring.io/projects/spring-boot#learn)

**注意：** Spring Boot 版本变化快，最新版本以官网为准。

|                       Spring Framework                       |                         Spring Boot                          |                     System Requirements                      |        boot support         |
| :----------------------------------------------------------: | :----------------------------------------------------------: | :----------------------------------------------------------: | :-------------------------: |
| [5.3.31](https://docs.spring.io/spring-framework/docs/5.3.31/reference/html/)+ | [2.7.18](https://docs.spring.io/spring-boot/docs/2.7.18/reference/html/) |   Java 8+/Maven 3.5+/Gradle 6.8.x+/Tomcat 9.0/Undertow 2.0   | 2.7.x/2022-05-19/2023-06-30 |
| [6.0.14](https://docs.spring.io/spring-framework/reference/6.0/)+ | [3.0.13](https://docs.spring.io/spring-boot/docs/3.0.13/reference/html/) |   Java 17/Maven 3.5+/Gradle 7.5+/Tomcat 10.1/Undertow 2.3    | 3.0.x/2022-11-24/2023-12-31 |
| [6.0.21](https://docs.spring.io/spring-framework/reference/6.0/)+ | [3.1.12](https://docs.spring.io/spring-boot/docs/3.1.12/reference/html/) |  Java 17/Maven 3.6.3+/Gradle 7.5+/Tomcat 10.1/Undertow 2.3   | 3.1.x/2023-05-18/2024-06-30 |
| [6.1.x](https://docs.spring.io/spring-framework/reference/6.1/)+ | [3.2.12](https://docs.spring.io/spring-boot/docs/3.2.12/reference/html/) |  Java 17/Maven 3.6.3+/Gradle 7.5+/Tomcat 10.1/Undertow 2.3   | 3.2.x/2023-11-23/2024-12-31 |
| [6.1.17](https://docs.spring.io/spring-framework/reference/6.1/)+ |  [3.3.9](https://docs.spring.io/spring-boot/3.3/index.html)  | Java 17/Maven 3.6.3+/Gradle 7.5+/Tomcat 10.1.25+/Undertow 2.3 | 3.3.x/2024-05-23/2025-06-30 |
| [6.2.11+](https://docs.spring.io/spring-framework/reference/) | [3.4.10](https://docs.spring.io/spring-boot/3.4/index.html)  | Java 17/Maven 3.6.3+/Gradle 7.x+/Tomcat 10.1.25+/Undertow 2.3+ |    3.4.x/2024-11/2025-12    |
| [6.2.11+](https://docs.spring.io/spring-framework/reference/) |    [3.5.6](https://docs.spring.io/spring-boot/index.html)    | Java 17/Maven 3.6.3+/Gradle 7.6.4+/Tomcat 10.1.25+/Undertow 2.3+ |    3.5.x/2025-05/2026-06    |

## Spring Cloud 版本列表

[Spring Cloud 版本官方列表](https://spring.io/projects/spring-cloud#learn)

**注意：** Spring Cloud 版本变化快，最新版本以官网为准。

| spring cloud                                                 | spring boot                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [2021.0.9](https://docs.spring.io/spring-cloud/docs/2021.0.9/reference/html/) | [2.6.15](https://docs.spring.io/spring-boot/docs/2.6.15/reference/html/) |
| [2022.0.5](https://docs.spring.io/spring-cloud/docs/2022.0.5/reference/html/) | [3.0.13](https://docs.spring.io/spring-boot/docs/3.0.13/reference/html/) |
| [2023.0.5](https://docs.spring.io/spring-cloud-release/reference/2023.0/index.html) | [3.2.12](https://docs.spring.io/spring-boot/docs/3.2.12/reference/html/) |
| [2024.0.2](https://docs.spring.io/spring-cloud-release/reference/2024.0/index.html) | [3.4.7](https://docs.spring.io/spring-boot/3.4/index.html)   |



## Spring Boot 参数优先级

[Externalized Configuration Link](https://docs.spring.io/spring-boot/docs/2.7.18/reference/html/features.html#features.external-config)

1. Command line arguments.
2. Java System properties (`System.getProperties()`).
3. OS environment variables.
4. Config data (such as `application.properties` files).



Spring Boot uses a very particular `PropertySource` order that is designed to allow sensible overriding of values. **Later property sources can override the values defined in earlier ones.** Sources are considered in the following order:

1. Default properties (specified by setting `SpringApplication.setDefaultProperties`).
2. [`@PropertySource`](https://docs.spring.io/spring-framework/docs/5.3.31/javadoc-api/org/springframework/context/annotation/PropertySource.html) annotations on your `@Configuration` classes. Please note that such property sources are not added to the `Environment` until the application context is being refreshed. This is too late to configure certain properties such as `logging.*` and `spring.main.*` which are read before refresh begins.
3. Config data (such as `application.properties` files).
4. A `RandomValuePropertySource` that has properties only in `random.*`.
5. OS environment variables.
6. Java System properties (`System.getProperties()`).
7. JNDI attributes from `java:comp/env`.
8. `ServletContext` init parameters.
9. `ServletConfig` init parameters.
10. Properties from `SPRING_APPLICATION_JSON` (inline JSON embedded in an environment variable or system property).
11. Command line arguments.
12. `properties` attribute on your tests. Available on [`@SpringBootTest`](https://docs.spring.io/spring-boot/docs/2.7.18/api/org/springframework/boot/test/context/SpringBootTest.html) and the [test annotations for testing a particular slice of your application](https://docs.spring.io/spring-boot/docs/2.7.18/reference/html/features.html#features.testing.spring-boot-applications.autoconfigured-tests).
13. [`@DynamicPropertySource`](https://docs.spring.io/spring-framework/docs/5.3.31/javadoc-api/org/springframework/test/context/DynamicPropertySource.html) annotations in your tests.
14. [`@TestPropertySource`](https://docs.spring.io/spring-framework/docs/5.3.31/javadoc-api/org/springframework/test/context/TestPropertySource.html) annotations on your tests.
15. [Devtools global settings properties](https://docs.spring.io/spring-boot/docs/2.7.18/reference/html/using.html#using.devtools.globalsettings) in the `$HOME/.config/spring-boot` directory when devtools is active.



**Config data files are considered in the following order:**

1. [Application properties](https://docs.spring.io/spring-boot/docs/2.7.18/reference/html/features.html#features.external-config.files) packaged inside your jar (`application.properties` and YAML variants).
2. [Profile-specific application properties](https://docs.spring.io/spring-boot/docs/2.7.18/reference/html/features.html#features.external-config.files.profile-specific) packaged inside your jar (`application-{profile}.properties` and YAML variants).
3. [Application properties](https://docs.spring.io/spring-boot/docs/2.7.18/reference/html/features.html#features.external-config.files) outside of your packaged jar (`application.properties` and YAML variants).
4. [Profile-specific application properties](https://docs.spring.io/spring-boot/docs/2.7.18/reference/html/features.html#features.external-config.files.profile-specific) outside of your packaged jar (`application-{profile}.properties` and YAML variants).



> It is recommended to stick with one format for your entire application. If you have configuration files with both `.properties` and YAML format in the same location, `.properties` takes precedence.



## Spring Boot 配置文件优先级

[External Application Properties Link](https://docs.spring.io/spring-boot/docs/2.7.18/reference/html/features.html#features.external-config.files)

Spring Boot will automatically find and load `application.properties` and `application.yaml` files from the following locations when your application starts:

1. From the classpath
   1. The classpath root
   2. The classpath `/config` package
2. From the current directory
   1. The current directory
   2. The `config/` subdirectory in the current directory
   3. Immediate child directories of the `config/` subdirectory

The list is ordered by precedence (with values from lower items overriding earlier ones). Documents from the loaded files are added as `PropertySources` to the Spring `Environment`.