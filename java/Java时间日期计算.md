---
title: "Java日期时间计算"
subtitle: "Java日期时间计算"
description: "Java日期时间计算|LocalDate|LocalDateTime"
date: 2025-03-17T23:36:09+08:00
lastmod: 2025-03-17T23:36:09+08:00
draft: false

authors: ["yzx"]
tags: ["Java"]
categories: []
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_1417.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# Java时间和日期计算

## 示例代码

```java
void testDate() {
    DateTimeFormatter df = DateTimeFormatter.ofPattern("yyyy-MM");
    DateTimeFormatter df2 = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    String zone8 = "+08:00";
    // String zone8 = "+8";

    // 北京时间要比格林威治时间（1970/01/01[UTC/GMT]）多 8 个小时，

    LocalDate now = LocalDate.now();
    // 当天开始时间
    LocalDateTime startOfDay = now.atStartOfDay();
    LocalDateTime toDayEnd = LocalDateTime.of(now, LocalTime.MAX);
    System.out.println("当天时间 [" + df2.format(startOfDay) + "] -> [" + df2.format(toDayEnd) + "]");
    System.out.println("当天时间戳 [" + startOfDay.toInstant(ZoneOffset.of(zone8)).toEpochMilli() +
            "] -> [" + toDayEnd.toInstant(ZoneOffset.of(zone8)).toEpochMilli() + "]");
    // 一周
    LocalDate monday = now.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
    LocalDate sunday = now.with(TemporalAdjusters.nextOrSame(DayOfWeek.SUNDAY));
    LocalDateTime mondayStartOfDay = monday.atStartOfDay();
    LocalDateTime sundayStartOfDay = sunday.atStartOfDay();
    System.out.println("当前周 [" + df2.format(mondayStartOfDay) + "] -> [" + df2.format(sundayStartOfDay) + "]");

    // 本周开始 -> 结束时间
    LocalDateTime weekStart = monday.atStartOfDay();
    LocalDateTime weekEnd = LocalDateTime.of(sunday, LocalTime.MAX);
    System.out.println("当前周时间段 [" + df2.format(weekStart) + "] -> [" + df2.format(weekEnd) + "]");

    // 本月
    LocalDate firstDayOfMonth = now.with(TemporalAdjusters.firstDayOfMonth());
    LocalDate lastDayOfMonth = now.with(TemporalAdjusters.lastDayOfMonth());
    LocalDateTime firstDayOfMonthTime = firstDayOfMonth.atStartOfDay();
    LocalDateTime lastDayOfMonthTime = LocalDateTime.of(lastDayOfMonth, LocalTime.MAX);
    System.out.println("当前月时间段 [" + df2.format(firstDayOfMonthTime) + "] -> [" + df2.format(lastDayOfMonthTime) + "]");

    // 本年数据
    int lengthOfYear = now.lengthOfYear();
    WeekFields weekFields = WeekFields.of(DayOfWeek.MONDAY, 4);
    int weekIndex = now.with(TemporalAdjusters.lastDayOfYear()).get(weekFields.weekOfWeekBasedYear());
    System.out.println("本年有 [" + lengthOfYear + "] 天，本周是第 [" + weekIndex + "] 周");

    List<Pair<LocalDateTime, LocalDateTime>> dateRangeList = new ArrayList<>();
    System.out.println("=================");
    LocalDate nowDate = LocalDate.now().minusMonths(12);
    // 最近 12 个月每个月的时间范围，不包含当前月
    for (int i = 0; i < 12; i++) {
        LocalDate monthDate = nowDate.plusMonths(i);
        // 2025-02
        System.out.println(df.format(monthDate));
        LocalDate firstDateOfMonth = monthDate.with(TemporalAdjusters.firstDayOfMonth());
        LocalDate lastDateOfMonth = monthDate.with(TemporalAdjusters.lastDayOfMonth());
        LocalDateTime monthStartOfDay = firstDateOfMonth.atStartOfDay();
        LocalDateTime monthLastOfDay = LocalDateTime.of(lastDateOfMonth, LocalTime.MAX);
        // 2025-02-01 00:00:00 / 2025-02-28 23:59:59
        dateRangeList.add(new Pair<>(monthStartOfDay, monthLastOfDay));
    }

    dateRangeList.forEach(v -> System.out.println(df2.format(v.getKey()) + " / " + df2.format(v.getValue())));

    System.out.println("--------");

}
```

