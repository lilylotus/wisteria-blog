---
title: "Vue3 简单教程"
subtitle: "Vue3 简单教程|Vue3 入门"
description: "Vue3 简单教程"
date: 2025-10-08T15:06:09+08:00
lastmod: 2025-10-08T15:06:09+08:00
draft: false

authors: ["yzx"]
tags: ["Vue"]
categories: ["Vue"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_2328.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# Vue3 简单教程

[Vue 官网](https://vuejs.org/)， [Vue 开始文档](https://vuejs.org/guide/introduction.html)

## 创建Vue应用

环境准备：

- [Node.js](https://nodejs.org/zh-cn) 版本 `^20.19.0 || >=22.12.0` （[Node.js v22.19.0 下载链接](https://nodejs.org/dist/v22.19.0/node-v22.19.0-x64.msi)）

npm 创建 Vue 应用：

```bash
$ npm create vue@latest
```

> *  请选择要包含的功能： (↑/↓ 切换，空格选择，a 全选，回车确认)
> |  [+] TypeScript （仅需要选择 TypeScript 插件就好）
> |  [ ] JSX 支持
> |  [ ] Router（单页面应用开发）
> |  [ ] Pinia（状态管理）
> |  [ ] Vitest（单元测试）
> |  [ ] 端到端测试
> |  [ ] ESLint（错误预防）
> |  [ ] Prettier（代码格式化）
> —

运行 Vue 应用：

```bash
$ cd vue3_hello
$ npm install
$ npm run dev
```

## Vue初始化目录简介

- [Vite](https://vite.dev/) 项目中 `index.html` 是项目的入口文件，在项目最外层。
- 加载 `index.html` 后 [Vite](https://vite.dev/) 解析 `<script type="module" src="xxx"></script>` 指向 `JavaScript`。
- `Vue3` 中通过 `src/main.ts` 中  `createApp` 函数创建一个应用实例。

重要文件：

- `src/main.ts`

```typescript
// 引入 createApp 用来创建应用实例
import {createApp} from 'vue'
// 引入 App 根组件
import App from './App.vue'

// 创建应用实例并挂载
createApp(App).mount('#app')
```

- `src/App.vue`

```vue
<template>
    <!--  html -->
</template>

<script lang="ts">
// JS 或 TS
</script>

<style>
/* CSS 或 SCSS */
</style>
```

## Vue3核心语法

### API 风格

Vue 的组件可以按两种不同的风格书写：**[选项式 API](https://cn.vuejs.org/guide/introduction#options-api)** 和 **[组合式 API](https://cn.vuejs.org/guide/introduction#composition-api)**。

- `Vue2` 的 `API` 设计是 `Options` （配置）风格。[options-api](https://vuejs.org/guide/introduction.html#options-api)
- `Vue3` 的 `API` 设计是 `Composition` （组合）风格。[Composition-api](https://vuejs.org/guide/introduction.html#composition-api)

#### 选项式 API (Options API)

使用选项式 API，我们可以用包含多个选项的对象来描述组件的逻辑，例如 `data`、`methods` 和 `mounted`。选项所定义的属性都会暴露在函数内部的 `this` 上，它会指向当前的组件实例。

```vue
<script>
export default {
  // data() 返回的属性将会成为响应式的状态
  // 并且暴露在 `this` 上
  data() {
    return {
      count: 0;
    }
  },

  // methods 是一些用来更改状态与触发更新的函数
  // 它们可以在模板中作为事件处理器绑定
  methods: {
    increment() {
      this.count++
    }
  },

  // 生命周期钩子会在组件生命周期的各个不同阶段被调用
  // 例如这个函数就会在组件挂载完成后被调用
  mounted() {
    console.log(`The initial count is ${this.count}.`)
  }
}
</script>

<template>
  <button @click="increment">Count is: {{ count }}</button>
</template>
```

#### 组合式 API (Composition API)

通过组合式 API，可以使用导入的 API 函数来描述组件逻辑。在单文件组件中，组合式 API 通常会与 [`<script setup>`](https://cn.vuejs.org/api/sfc-script-setup.html) 搭配使用。这个 `setup` attribute 是一个标识，告诉 Vue 需要在编译时进行一些处理，让我们可以更简洁地使用组合式 API。比如，`<script setup>` 中的导入和顶层变量/函数都能够在模板中直接使用。

```vue
<script setup>
import { ref, onMounted } from 'vue'

// 响应式状态
const count = ref(0)

// 用来修改状态、触发更新的函数
function increment() {
  count.value++
}

// 生命周期钩子
onMounted(() => {
  console.log(`The initial count is ${count.value}.`)
})
</script>

<template>
  <button @click="increment">Count is: {{ count }}</button>
</template>
```

### setup

#### 简单写法：

```vue
<script lang="ts">
    export default {
        name: 'Person',
        // 选项式 API 的 data 和 methods 与 setup 函数可以同时存在， setup 优先级更高
        // setup 函数中定义的同名数据和方法会覆盖选项式 API 中的
        // setup 函数中数据和方法可以在 data 和 methods 中访问，但反过来不行
        setup() {
            // 组合式 API 代码
            // 数据，注意：此时的数据还不是响应式的
            let name = '幸运';
            let age = 18;
            let telphone = '15212345678';

            // console.log("@@", this); // setup 函数中的 this 是 undefined

            // 方法
            function showTelphone() {
                alert(`电话号码: ${telphone}`);
            }
            function editName() {
                name = '小明'; // 注意：方法中 name 值是改了但是页面值 name 没有变化             			    console.log(name); // （name 不是响应式的）
            }
            return {name, age, telphone, showTelphone, editName }
        }
    }
</script>
```

#### 优雅写法，语法糖（复杂写法）：

```vue
<script lang="ts">
    export default {
        name: 'Person'
    }
</script>

<script lang="ts" setup>
    let name = '幸运';
    let age = 18;
    let telphone = '15212345678';

    function showTelphone() {
        alert(`setup->电话号码: ${telphone}`);
    }
</script>
```

#### 优雅写法，语法糖（简写模式）：

安装 `setup` 拓展插件： `npm i vite-plugin-vue-setup-extend -D`

在 `vite.config.ts` 添加 `setup` 拓展插件配置：

```ts
import VueSetupExtend from 'vite-plugin-vue-setup-extend';

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    VueSetupExtend()
  ]
})
```

```vue
<!-- 使用 vite-plugin-vue-setup-extend 插件，可以在 <script setup> 中使用 name 属性指定组件名称 -->
<script lang="ts" setup name="Person">
    // 还不是响应式数据
    let name = '幸运';
    let age = 18;
    let telphone = '15212345678';

    function showTelphone() {
        alert(`setup->电话号码: ${telphone}`);
    }
</script>
```

#### 优雅写法 setup 响应式

- [ref()](https://cn.vuejs.org/guide/essentials/reactivity-fundamentals.html#ref)  适合基本数据类型（响应式数据），也适用与对象类型响应式数据 `ref(reactive(对象))`，ref 针对对象底层也是使用的 reactive 做代理的
- [reactive()](https://cn.vuejs.org/guide/essentials/reactivity-fundamentals.html#reactive) **只能定义** 对象数据类型（响应式数据），深层次的响应式对象（对象层级可以递归）【响应式对象】

注意区别：

- `reactive` 重新分配对象后会失去响应式效果，推荐使用 `Object.assign` 函数赋值保留响应式对象
- `ref` 因为使用 `.value` 来操作值所有不会丢失响应式对象

使用原则：

> 1. 若是需要一个基本类型的响应式数据，必须使用 `ref`
> 2. 若是需要一个响应式对象，层级不深，`ref` / `reactive` 都可以
> 3. 若是需要一个响应式对象，且层级较深，推荐使用 `reactive` （表单数据回显）

```vue
<!-- // 使用 vite-plugin-vue-setup-extend 插件，可以在 <script setup> 中使用 name 属性 -->
<script lang="ts" setup name="Person">
    import { reactive, ref } from 'vue';

    const name = ref('幸运'); // ref 创建响应式数据，ref 适合基本数据类型
    const age = ref(18); // ref 创建响应式数据，ref 适合基本数据类型
    const address = '中国'; // 普通变量，非响应式数据
    const telphone = '15212345678'; // 普通变量，非响应式数据

    // reactive 创建响应式数据，适合对象类型（数组，对象）
    const car = reactive({brand: '宝马', price: 50});
    // Proxy() 原生 JS 创建响应式数据，代理对象
    console.log("car", car);
    
    // 响应式数组
    let flowers = reactive([
        {name: '玫瑰', color: '红色'},
        {name: '郁金香', color: '黄色'},
        {name: '向日葵', color: '黄色'},
        {name: '紫罗兰', color: '紫色'},
        {name: '百合', color: '白色'}
    ]);
    
    let replaceObj = reactive({a: 1, b: 2});
    
    function showTelphone() {
        alert(`setup->电话号码: ${telphone}`);
    }
    function editName() {
        name.value = '小明'; // 修改 ref 响应式数据，需要使用 .value
        console.log(name.value); // 访问 ref 响应式数据，需要使用 .value
    }
    function editCarPrice() {
        car.price += 5; // 修改 reactive 响应式数据，直接修改
        console.log(car.price);
    }
    function editFlowerInfo() {
        flowers[0].color = '粉色'; // 修改数组对象的属性，直接修改，响应式更新
        flowers.push({name: '风信子', color: '蓝色'}); // 添加新元素，直接修改，响应式更新
        console.log(flowers);
    }
    function replaceReactiveObj() {
        // 不能直接替换 reactive 对象，否则失去响应式
        // replaceObj = {a: 3, b: 4}; // 错误示范
        // 正确做法，修改属性值
        replaceObj.a = 3;
        replaceObj.b = 4;
        console.log(replaceObj);
        // 可以用 reactive 包裹新对象，重新赋值，但是界面不会更新，把原来的响应式丢掉了
        replaceObj = reactive({a: 3, b: 4});
        // 推荐用 Object.assign() 合并新对象，保留响应式
        Object.assign(replaceObj, {a: 3, b: 4});
    }
</script>
```

### toRefs 和 toRef

[toRefs 函数](https://cn.vuejs.org/api/reactivity-utilities.html#torefs) / [toRef 函数](https://cn.vuejs.org/api/reactivity-utilities.html#toref)

```vue
<script lang="ts" setup name="Person">
    import { reactive, ref, toRefs, toRef } from 'vue';
    // toRefs 和 toRef
    // import { toRefs, toRef } from 'vue';
    let person = reactive({
        pname: '张三',
        page: 20,
        paddress: '北京'
    });
    // toRefs 将对象的每个属性都转换为 ref 响应式数据
    // 修改 pname, page, padress 上面对象的响应式 person 数据也会相应修改
    let { pname, page, paddress } = toRefs(person);
    // toRef 将对象的某个属性转换为 ref 响应式数据
    // 修改 toRefpname 上面响应式 person 数据中 pname 数据也会相应修改
    let toRefpname = toRef(person, 'pname');

    // 组合式 API 代码，setup 方法
    function editToRefsData() {
        pname.value += '+';
        page.value += 1;
        paddress.value += '+';
        console.log(pname, page, paddress);
    }
    function editToRefData() {
        toRefpname.value += '@';
        console.log(toRefpname);
    }
</script>
```

### computed 计算属性

```vue
<template>
    <div class="person">
        <!-- v-bind:value 单向绑定，修改数据无法反向更新 -->
        <!-- v-model 双向绑定，修改数据可以反向更新 -->
        姓：<input type="text" v-model="firstName"> <br>
        名：<input type="text" v-model="lastName"> <br>
        姓名：<span>{{fullName}}</span> <br>
        <button @click="fullName = '吉-祥'">修改姓名为 吉-祥</button>
    </div>
</template>

<!-- // 使用 vite-plugin-vue-setup-extend 插件，可以在 <script setup> 中使用 name 属性 -->
<script lang="ts" setup name="Person">
    import { ref, computed } from 'vue';

    let firstName = ref('幸');
    let lastName = ref('运');

    // 计算属性 computed, 依赖的响应式数据变化时计算属性会重新计算，有缓存
    // import { computed } from 'vue';
    // 这么定义的计算属性是不可写的，只能读
    // let fullName = computed(() => {
    //     return `${firstName.value}-${lastName.value}`;
    // });

    // 这么定义的计算属性是可读可写的，可以通过赋值修改依赖的响应式数据
    // 注意：计算属性的 set 方法不会传入旧值，只会传入新值
    // computed 也是一个引用类型，需要通过 .value 访问
    let fullName = computed({
        get() {
            return `${firstName.value}-${lastName.value}`;
        },
        set(value) {
            const [first, last] = value.split('-');
            firstName.value = first;
            lastName.value = last;
        }
    });
</script>
```

### watch 侦听响应式数据

[watch() 函数](https://cn.vuejs.org/api/reactivity-core.html#watch)，`watch()` 默认是懒侦听的，即仅在侦听源发生变化时才执行回调函数。

监视响应式数据变化，可以监视以下四种数据：

1. `ref` 定义的响应式数据
2. `reactive` 定义的响应式数据
3. 一个函数，返回一个值
4. 是由以上类型的值组成的数组

#### 监视 `ref` 简单数据类型

```vue
<!-- // 使用 vite-plugin-vue-setup-extend 插件，可以在 <script setup> 中使用 name 属性 -->
<script lang="ts" setup name="Person">
    import { ref, watch } from 'vue';

    let sum = ref(0);
   
    // 监听 sum 的变化，ref 简单基本类型数据 watch(响应式简单基本类型数据, 回调函数)
    const stopWatch = watch(sum, (newVal, oldVal) => {
        console.log(`sum 从 ${oldVal} 变为 ${newVal}`);
        if (newVal >= 10) {
            console.log('sum 已经大于 10 不能再加了');
            // 停止监听
            stopWatch();
        }
    });
    // console.log('stopWatch:', stopWatch);
</script>
```

#### 监视 `ref` 对象数据类型

```vue
<!-- // 使用 vite-plugin-vue-setup-extend 插件，可以在 <script setup> 中使用 name 属性 -->
<script lang="ts" setup name="Person">
    import { ref, watch } from 'vue';

    let person = ref({ name: '幸运星', age: 18 });

    function editPersonName() {
        person.value.name += '星'; // 若没开启 deep 深度监视，不会监听
    }
    function changePerson() {
        person.value = { name: '小星星', age: 20 };
    }
    // 监听 person 的变化，ref 响应式复杂对象类型数据 watch(监视响应式复杂对象数据, 回调函数, 配置选项)
    // 默认情况下，监听对象的引用地址变化，如果要监听对象内部值的变化，需要设置 deep: true
    // 修改内部属性 newVal 和 oldVal 都是同一个对象地址，所以无法获取到变化前的值
    // 修改对象引用地址 newVal 和 oldVal 是不同的对象地址，可以获取到变化前的值
    // immediate: true 立即执行一次回调函数
    watch(person, (newVal, oldVal) => {
            console.log('person 发生变化了');
            console.log('oldVal:', oldVal);
            console.log('newVal:', newVal);
        },
        {
            deep: true, 
            immediate: true
        }
    );
</script>
```

#### 监视 `reactive` 响应对象数据

```vue
<!-- // 使用 vite-plugin-vue-setup-extend 插件，可以在 <script setup> 中使用 name 属性 -->
<script lang="ts" setup name="Person">
    import { ref, reactive, watch } from 'vue';

    let reactivePerson = reactive({name: '吉祥星', age: 18});

    function editReactivePersonName() {
        reactivePerson.name += '祥';
    }
    function changeReactivePerson() {
        // reactivePerson = { name: 'reactive小星星', age: 20 };
        // 不能直接修改 reactivePerson 的引用地址，可以通过 Object.assign() 方法修改
        Object.assign(reactivePerson, { name: 'reactive小星星', age: 20 });
    }
    // 监听 reactivePerson 的变化，reactive 响应式复杂对象类型数据 watch(监视响应式复杂对象数据, 回调函数, 配置选项)
    // watch 监听 reactive 创建的响应式对象时，不需要设置 deep: true，默认就是深度监听，隐式开启无法关闭
    // 修改内部属性 newVal 和 oldVal 都是同一个对象地址，所以无法获取到变化前的值
    // 修改 reactive 响应式对象，其引用对象地址未发生变化，所以 newVal 和 oldVal 也是同一个对象地址
    watch(reactivePerson, (newVal, oldVal) => {
            console.log('reactivePerson 发生变化了', oldVal, newVal);
        }
    );
</script>
```

#### 监听响应式对象数据中的某个属性

```vue
<!-- // 使用 vite-plugin-vue-setup-extend 插件，可以在 <script setup> 中使用 name 属性 -->
<script lang="ts" setup name="Person">
    import { ref, reactive, watch } from 'vue';
    
    let reactivePerson = reactive({
        name: '吉祥星',
        age: 18,
        habby: { sport: '篮球', game: '王者荣耀' }
    });

    // watch 监听 reactive 创建的响应式对象中的某个属性，且其属性为基本数据类型
    // 基本数据类型需要写为一个 getter 函数，一个函数，返回一个值
    watch(() => reactivePerson.age, (newVal, oldVal) => {
        console.log(`reactivePerson.age 从 ${oldVal} 变为 ${newVal}`);
    });
    
    // watch 监听 reactive 创建的响应式对象中的某个对象属性
    // 建议写成函数形式，避免报错，整体性能更好，更灵活，更安全，但是仅修改整个对象属性时，才会触发回调函数
    // 配置 deep: true，可以监听对象内部属性的变化
    watch(() => reactivePerson.habby, (newVal, oldVal) => {
        console.log('reactivePerson.habby 发生变化了', oldVal, newVal);
    }, { deep: true });
</script>
```

#### 监听响应式对象数据数组

```vue
<!-- // 使用 vite-plugin-vue-setup-extend 插件，可以在 <script setup> 中使用 name 属性 -->
<script lang="ts" setup name="Person">
    import { ref, reactive, watch } from 'vue';
    
    let reactivePerson = reactive({
        name: '吉祥星',
        age: 18,
        habby: { sport: '篮球', game: '王者荣耀' }
    });

    // watch 监听上述数组中某个对象属性，通过数组形式，可以监听多个属性的变化
    watch([() => reactivePerson.name, () => reactivePerson.habby], (newVal, oldVal) => {
        console.log('reactivePerson.habby 发生变化了');
        console.log('oldVal:', oldVal);
        console.log('newVal:', newVal);
    }, { deep: true });
</script>
```

### watchEffect

[watchEffect()](https://cn.vuejs.org/api/reactivity-core.html#watcheffect)

```vue
<!-- // 使用 vite-plugin-vue-setup-extend 插件，可以在 <script setup> 中使用 name 属性 -->
<script lang="ts" setup name="Person">
    import { ref, watch, watchEffect } from 'vue';

    let wA = ref(10);
    let wB = ref(0);

    // 使用 watch 监听多个数据变化
    // watch([wA, wB], (newValue) => {
    //     let [na, nb] = newValue;
    //     if (na >= 60 || nb >= 30) {
    //         console.log('数据变化了，通知', na, nb);
    //     }
    // });

    // 使用 watchEffect 监听多个数据变化
    constant stop = watchEffect(() => {
        if (wA.value >= 60 || wB.value >= 30) {
            console.log('数据变化了，通知', wA.value, wB.value);
        }
    });
    
    // 当不再需要此侦听器时:
    stop();

</script>
```

### ref 标签

```vue
<template>
    <div class="person">
        <h2 ref="htmlItem">====== watchEffect 监听数据变化 ======</h2>
        <button @click="showHtmlItem">点击显示 html 元素</button>
    </div>
	<!-- 下面就可以使用 refPerson 对象使用 Person 组件的指定暴露数据 a,b,c -->
	<Person ref="refPerson"/>
</template>

<!-- // 使用 vite-plugin-vue-setup-extend 插件，可以在 <script setup> 中使用 name 属性 -->
<script lang="ts" setup name="Person">
    import { ref, watch, watchEffect, defineExpose } from 'vue';
	
    // ref 放到普通 html DOM 元素，获取到的就是 DOM 元素节点
    // ref 放到组件标签上，获取到的就是组件示例对象
    let htmlItem = ref();

    let a = ref(10);
    let b = ref(20);
    let c = ref(30);

    function showHtmlItem() {
        console.log('html 元素', htmlItem.value);
    }
    
    // 指定其它组件 Component 使用 ref 时可以看到的数据
    defineExpose({a, b, c});

</script>
```

### TypeScript

`src/types/index.ts`

```typescript
// 定义一个接口，用于限制对象的数据结构
// export 分别暴露，供其他模块单独引入，也可以整体引入
export interface PersonInterface {
    id: string,
    name: string,
    age: number,
    address?: string  // 可选属性
}

// 一个自定义类型
export type Persons = Array<PersonInterface>;
```

`App.vue`

```vue
<script lang="ts" setup name="Person">
    import { reactive } from 'vue';
    import { type PersonInterface, type Persons } from '@/types';
    // 定义一个符合 PersonInterface 接口的对象
    let person: PersonInterface = {
        id: '1',
        name: 'John Doe',
        age: 30
    };

    // 定义一个数组，包含多个符合 PersonInterface 接口的对象
    let personList: Array<PersonInterface> = [
        { id: '1', name: 'Alice', age: 25 },
        { id: '2', name: 'Bob', age: 28 },
        { id: '3', name: 'Charlie', age: 22 }
    ];

    let personList2: PersonInterface[] = [
        { id: '4', name: 'David', age: 35 },
        { id: '5', name: 'Eve', age: 29 },
        { id: '6', name: 'Frank', age: 33 }
    ];

    let personList3: Persons = [
        { id: '7', name: 'Grace', age: 27 },
        { id: '8', name: 'Heidi', age: 31, address: '456 Elm St' },
        { id: '9', name: 'Ivan', age: 26 }
    ];

    // 使用 reactive 创建一个响应式对象
    let reactivePersons = reactive<Persons>([
        { id: '10', name: 'Jack', age: 24 },
        { id: '11', name: 'Kathy', age: 32, address: '789 Pine St' },
        { id: '12', name: 'Leo', age: 28 , address: '123 Main St'}
    ]);

</script>
```

### 访问 Props

[props()](https://cn.vuejs.org/api/composition-api-setup.html#accessing-props)

`ComponentA.vue`

```vue
<template>
    <ComponentB propA="ValueA" :list="reactivePersons" :var="variables" ref="reactivePersons"/>
</template>

<script lang="ts" setup name="ComponentA">
	import ComponentB from './components/ComponentB.vue';
	import { type PersonInterface, type Persons } from '@/types';
    
    // 使用 reactive 创建一个响应式对象
    let reactivePersons = reactive<Persons>([
        { id: '10', name: 'Jack', age: 24 },
        { id: '11', name: 'Kathy', age: 32, address: '789 Pine St' },
        { id: '12', name: 'Leo', age: 28 , address: '123 Main St'}
    ]);
</script>
```

`ComponentB.vue`

```vue
<template>
    <div class="person">
        <h2>访问标记值{{ propsVar.propA }}</h2>
        <h2>访问标记值{{ propA }}</h2>
    </div>
</template>

<!-- // 使用 vite-plugin-vue-setup-extend 插件，可以在 <script setup> 中使用 name 属性 -->
<script lang="ts" setup name="ComponentB">
    import { defineProps, withDefaults } from 'vue';

    // 定义组件的 props
    let propsVar = defineProps(['propA', "list"]);
    console.log('propsVar:', propsVar); // 输出: { propA: 'ValueA' }
    
    // 使用类型定义 props，list? 父级参数可传可不传
    let propsVar = defineProps<{ propA: string, list?: Persons }>();

    // 使用类型定义 props，并设置默认值
    let propsVar = withDefaults(defineProps<{ propA: string, list: Persons }>(), {
        list: () => ([
            { id: '123', name: '张三', age: 18, address: '123 Main St' },
            { id: '456', name: '李四', age: 20 }
        ])
    });
    
</script>
```

## 生命周期

[生命周期](https://cn.vuejs.org/guide/essentials/lifecycle.html)

注意：是先挂载子组件在挂载父组件（递归执行）

```vue
<script lang="ts" setup name="Person">
    import { onBeforeMount, onMounted, onBeforeUpdate, onUpdated, onBeforeUnmount, onUnmounted } from 'vue';

    // 生命周期钩子
    console.log('组件加载');

    onBeforeMount(() => {
        console.log('挂载前');
    });
    onMounted(() => {
        console.log('挂载后');
    });
    onBeforeUpdate(() => {
        console.log('更新前');
    });
    onUpdated(() => {
        console.log('更新后');
    });
    onBeforeUnmount(() => {
        console.log('卸载前');
    });
    onUnmounted(() => {
        console.log('卸载后');
    });
</script>
```

## hooks 钩子组件

命名规范 `useXxxx`

`src/hooks/useSum.ts`

```typescript
import { ref } from "vue";
// 所有的 vue 函数都可以在这里使用
export default function () {
    const sum = ref(0);
    const add = (value: number) => {
        sum.value += value;
    };
    return { sum, add };
}
```

`Sum.vue`

```vue
<script lang="ts" setup name="Sum">
    import useSum from '@/hooks/useSum';
    const { sum, add } = useSum();
    add(10);
    // 下面就可以直接使用
</script>
```

## 路由

[Vue Router 路由官方参考文档](https://router.vuejs.org/zh/guide/)

安装路由组件：`npm i vue-router`

建立 `router` 路由目录`src/router` 和路由索引文件 `src/router/index.ts`

```typescript
// 创建一个路由器并暴露出去让Vue应用使用
// 1. 引入createRouter函数
import { createRouter, createWebHistory } from "vue-router";
// 2. 引入组件
import Home  from "@/component/Home.vue";
import About from "@/component/About.vue";
import Detail from "@/component/Detail.vue";
// 3. 创建路由器
const router = createRouter({
    history: createWebHistory(), // 使用HTML5的history模式
    routes: [
        // 配置路由规则，每一条路由规则是一个对象
        { path: "/", component: Home },
        { path: "/about", component: About,
          children: [ // 子级路由
              { path: "detail", component: Detail }
          ]
        }
    ]
});

// 4. 暴露路由器
export default router;
```

创建对应组件：`Home.vue` / `About.vue`

```vue
<template>
    <div class="home">
        <h2>Home</h2>
        <p>欢迎来到 Vue3 + TypeScript 的世界！</p>
        <!-- 下级导航内容 -->
        <p>以下是一些最新的财经新闻：</p>
        <ul>
            <li v-for="news in financeNewsList" :key="news.id">
                <!-- 子级路由链接 -->
                <RouterLink to="/finance/detail">{{ news.title }}</RouterLink>
            </li>
        </ul>
        <div class="news-content">
            <!-- 子级路由内容展示区域 -->
            <RouterView></RouterView>
        </div>
    </div>
</template>

<script lang="ts" setup name="Home">
    import { reactive, onMounted, onUnmounted } from 'vue';
    import { RouterView, RouterLink } from 'vue-router';
    // 生命周期钩子，在路由规则匹配时渲染加载，消失移开时挂载，在下次展示时再次渲染挂载
    onMounted(() => {
        console.log('Home component mounted');
    });
    onUnmounted(() => {
        console.log('Home component unmounted');
    });
    // 数据
    const financeNewsList = reactive([
        { id: 1, title: '2024年经济展望', content: '专家预测2024年经济将稳步增长，主要受益于科技创新和全球贸易复苏。' },
        { id: 2, title: '股市动态', content: '近期股市表现强劲，科技板块领涨，投资者信心提升。' },
        { id: 3, title: '房地产市场分析', content: '房地产市场趋于平稳，部分城市房价出现回调，购房者观望情绪浓厚。' },
    ]);
</script>

<style scoped>
    .home {
        display: flex;
        justify-content: center;
        align-items: center;
        height: 100%;
    }
</style>
```

`Detail.vue` 子级路由：

```vue
<template>
    <div class="detail">
        <h2>详情</h2>
        <p>编号：{{ route.query.id }}</p>
        <p>标题：{{ route.query.title }}</p>
        <p>内容：{{ route.query.content }}</p>
        <!-- 或者 -->
        <p>编号：{{ query.id }}</p>
        <p>标题：{{ query.title }}</p>
        <p>内容：{{ query.content }}</p>
    </div>
</template>

<script lang="ts" setup name="Detail">
    import { toRefs } from 'vue';
    import { useRoute } from 'vue-router';
    // 获取路由参数
    const route = useRoute();
    // 响应式数据解构，解构数据必定丢失响应式，需要使用 toRefs 进行转换为响应式数据
    const { query } = toRefs(route);
</script>

<style scoped>
</style>
```

`App.vue` 使用路由：

```vue
<template>
    <!--  html -->
    <div class="app">
        <h2 class="title">Vue路由示例</h2>
        <!-- 导航区 -->
        <div class="navigate">
            <!-- RouterLink 组件实现路由跳转 active-class 实现点击高亮 -->
            <RouterLink to="/" active-class="active">首页</RouterLink>
             <!-- :to 的第二种对象写法，path  -->
            <RouterLink :to="{path: '/about'}" active-class="active">关于</RouterLink>
        </div>
        <!-- 展示区域 -->
        <div class="content">
            <!-- 路由出口，展示匹配到的组件 -->
            <RouterView></RouterView>
        </div>
    </div>
</template>

<script lang="ts" setup name="App">
	// 引入路由组件
    import { RouterView, RouterLink } from 'vue-router'
</script>

<style scoped>
/* CSS 或 SCSS */
</style>
```

`main.ts` 引用路由组件：

```typescript
// 引入 createApp 用来创建应用实例
import {createApp} from 'vue'
// 引入 App 根组件
import App from './App.vue'
// 引入路由器
import router from './router'
// 创建应用实例并挂载
// createApp(App).mount('#app')
// 通过 use 方法将路由器安装到应用中，使得所有的组件都可以使用路由功能
createApp(App).use(router).mount('#app')
```

注意：默认格式目录

> 路由组件：靠路由规则匹配渲染出来的，如： routes: [ {path: '/test', component: Test}]，放到 `/pages` 或 `/views` 目录
>
> 一般组件：通过手写标签加载出来的，如： <Test/> ，放到 `/component` 目录
>
> 通过点击导航，界面消失的路由组件，默认是被 ”卸载“ 掉了，需要的时候再去 ”挂载“

### 路由器的工作模式

#### history 模式（HTML5 模式）

[HTML5 模式说明文档](https://router.vuejs.org/zh/guide/essentials/history-mode.html#Hash-%E6%A8%A1%E5%BC%8F)

当使用这种历史模式时，URL 会看起来很 "正常"，例如 `https://example.com/user/id`。漂亮!

不过，问题来了。由于我们的应用是一个单页的客户端应用，如果没有适当的服务器配置，用户在浏览器中直接访问 `https://example.com/user/id`，就会得到一个 404 错误。这就尴尬了。

不用担心：要解决这个问题，你需要做的就是在你的服务器上添加一个简单的回退路由。如果 URL 不匹配任何静态资源，它应提供与你的应用程序中的 `index.html` 相同的页面。漂亮依旧!

- 优点：`URL` 更加美观，路径中不带 `#` 号，更接近传统网站的 `URL`。
- 缺点：后期项目上线，需要服务端配合处理路径问题，否则刷新会出现 `404` 错误。

```typescript
import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(), // 使用HTML5的history模式
  routes: [
    //...
  ],
})
```

#### hash 模式

[Hash 模式说明文档](https://router.vuejs.org/zh/guide/essentials/history-mode.html#Hash-%E6%A8%A1%E5%BC%8F)

它在内部传递的实际 URL 之前使用了一个井号（`#`）。由于这部分 URL 从未被发送到服务器，所以它不需要在服务器层面上进行任何特殊处理。不过，**它在 SEO 中确实有不好的影响**。如果你担心这个问题，可以使用 HTML5 模式。

```typescript
import { createRouter, createWebHashHistory } from 'vue-router'

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    //...
  ],
})
```

### 路由参数

[路由组件传递参数参考文档](https://router.vuejs.org/zh/guide/essentials/passing-props.html)

#### query 参数

```typescript
<template>
    <div class="finance">
        <ul>
            <li v-for="news in financeNewsList" :key="news.id">
                <!-- 传递参数的第一种方式 -->
                <RouterLink to="/finance/detail?a=aValue&b=bValue&c=cValue">{{ news.title }}</RouterLink>
                <!-- 传递参数的第二种方式，尖括号语法 -->
                <RouterLink :to="`/finance/detail?id=${news.id}&title=${news.title}&content=${news.content}`">{{ news.title }}</RouterLink>
                <!-- 传递参数的第三种方式，对象语法 -->
                <RouterLink :to="{  path: '/finance/detail', query: { id: news.id, title: news.title, content: news.content } }">
                    {{ news.title }}
                </RouterLink>
            </li>
        </ul>
    </div>
</template>
```

使用 `route.query` 获取请求 query 参数

```vue
<template>
    <div class="detail">
        <h2>详情</h2>
        <p>编号：{{ route.query.id }}</p>
        <p>标题：{{ route.query.title }}</p>
        <p>内容：{{ route.query.content }}</p>
        <hr />
        <h3>使用 toRefs 解构后的响应式数据</h3>
        <p>编号：{{ query.id }}</p>
        <p>标题：{{ query.title }}</p>
        <p>内容：{{ query.content }}</p>

    </div>
</template>

<script lang="ts" setup name="Detail">
    import { toRefs } from 'vue';
    import { useRoute } from 'vue-router';
    // 获取路由参数
    const route = useRoute();
    // 响应式数据解构，解构数据必定丢失响应式，需要使用 toRefs 进行转换为响应式数据
    const { query } = toRefs(route);
</script>

<style scoped>
</style>
```

#### param 参数

注意：

- 传递 `params` 参数时若使用 `:to` 对象写法，必须使用 `name` 配置项，不能用 `path`
- 传递 `params` 参数时必须提前在规则中配置占位符，`/:id?`  标识此参数可以不传递

路由定义：

```typescript
// 3. 创建路由器
const router = createRouter({
    history: createWebHistory(), // 使用HTML5的history模式
    routes: [
        // 配置路由规则，每一条路由规则是一个对象
        {
            path: "/finance",
            name: "FinaceName",
            component: Finance,
            children: [
                // 指定参数路径，加 ? 标识此参数可以不传递
                { path: "detail/:id/:title/:content?", component: Detail }
            ]
        }
    ]
});
```

param

```typescript
<!-- 传递参数的第四种方式，params 方式 -->
<RouterLink to="/finance/detail/1/2024年经济展望/专家预测2024年经济将稳步增长，主要受益于科技创新和全球贸易复苏。">{{ news.title }}</RouterLink>

<!-- 使用模版字符串 -->
<RouterLink :to="`/finance/detail/${news.id}/${news.title}/${news.content}`">{{ news.title }}</RouterLink>

<!-- 传递 params 方式，对象写法，不能使用 path ，仅能使用 name -->
<RouterLink :to="{  name: 'FinanceDetail', params: { id: news.id, title: news.title, content: news.content } }">
{{ news.title }}
</RouterLink>
```

使用 `route.params` 获取请求 params 参数

```vue
<template>
    <div class="detail">
        <h2>详情</h2>
        <p>编号：{{ route.params.id }}</p>
        <p>标题：{{ route.params.title }}</p>
        <p>内容：{{ route.params.content }}</p>
        <hr />
        <h3>使用 toRefs 解构后的响应式数据</h3>
        <p>编号：{{ params.id }}</p>
        <p>标题：{{ params.title }}</p>
        <p>内容：{{ params.content }}</p>

    </div>
</template>

<script lang="ts" setup name="Detail">
    import { toRefs } from 'vue';
    import { useRoute } from 'vue-router';
    // 获取路由参数
    const route = useRoute();
    // 响应式数据解构，解构数据必定丢失响应式，需要使用 toRefs 进行转换为响应式数据
    const { query } = toRefs(route);
    const { params } = toRefs(route);
</script>

<style scoped>
</style>
```

#### props 配置

```typescript
// 3. 创建路由器
const router = createRouter({
    history: createWebHistory(), // 使用HTML5的history模式
    routes: [
        // 配置路由规则，每一条路由规则是一个对象
        {
            path: "/finance",
            component: Finance,
            children: [
                { 
                    path: "detail/:id/:title/:content",  // :id :title :content是占位符
                    name: "FinanceDetail",  // 给路由规则命名
                    component: Detail, // 详情页组件
// 第一种写法，开启props传参，仅将路由所有 params 参数映射到组件的props中，使用defineProps([id, title, content])接收
props: true
                    
// 第二种写法，函数写法，返回一个对象，对象中是要传递给组件的参数
props: (route) => {
	// return route.query; // 将路由的查询参数映射到组件的props中
	return route.params;
}
        
// 第三种写法，静态写法
props: { id: "001", title: "测试标题", content: "测试内容" }
                }
            ]
        }
    ]
});
```

直接使用参数

```vue
<template>
    <div class="detail">
        <h2>详情</h2>
        <h3>使用 defineProps 定义的 props</h3>
        <p>编号：{{ id }}</p>
        <p>标题：{{ title }}</p>
        <p>内容：{{ content }}</p>
    </div>
</template>

<script lang="ts" setup name="Detail">
    import { toRefs } from 'vue';
    import { useRoute } from 'vue-router';
    // 获取路由参数
    const route = useRoute();
    defineProps({ id: String, title: String, content: String });
</script>
```

#### replace 历史记录

模式是 `push` 模式

使用 `replace` 模式，路由后无法回去

```vue
<RouterLink replace to="/entertainment" active-class="active">娱乐</RouterLink>
```

#### 编程式导航（*）

写法一

```vue
<script lang="ts" setup name="Home">
    import { onMounted, onUnmounted } from 'vue';
    import { useRouter } from 'vue-router';
    const router = useRouter();
    // 生命周期钩子
    onMounted(() => {
        console.log('Home component mounted');
        setTimeout(() => {
            console.log('Home component mounted after 3 seconds');
            // 编程式导航跳转，脱离 <RouterLink> 组件跳转，使用 router.push() 方法
            // router.push() 方法参数和 <RouterLink> 组件的 to 属性参数一致
            router.push('/finance');
        }, 3000);
    });
</script>
```

写法二

```typescript
<script lang="ts" setup name="Finance">
    import { RouterView, RouterLink, useRouter } from 'vue-router';
    // 获取路由实例
    const router = useRouter();
    // 编程式导航，脱离 <RouterLink> 组件跳转，使用 router.push() 方法
    // router.push() 方法参数和 <RouterLink> 组件的 to 属性参数一致
    function viewDetail(news: { id: number; title: string; content: string }) {
        // 编程式导航，传递参数的第四种方式，params 方式
        // 注意：使用 params 方式传递参数时，路由必须使用 name 来跳转，不能使用 path
        // 否则会导致路由无法匹配，从而无法跳转
        // router.push() 会有历史记录，可以使用浏览器的前进后退按钮进行导航
        // router.replace() 不会有历史记录，无法使用浏览器的前进后退按钮进行导航
        router.push({ name: 'FinanceDetail', params: { id: news.id, title: news.title, content: news.content } });
    }
</script>
```

```vue
<template>
    <div class="finance">
        <h2>财经</h2>
        <p>欢迎来到 Vue3 + TypeScript 的世界！</p>
        <p>以下是一些最新的财经新闻：</p>
        <ul>
            <li v-for="news in financeNewsList" :key="news.id">
                   <!-- 传递 params 方式，对象写法，不能使用 path ，仅能使用 name -->
                 <RouterLink :to="{  name: 'FinanceDetail', params: { id: news.id, title: news.title, content: news.content } }">
                    {{ news.title }}
                </RouterLink>
                <button @click="viewDetail(news)">查看详情</button>
            </li>
        </ul>
        <div class="news-content">
            <RouterView></RouterView>
        </div>
    </div>
</template>
```

#### 重定向

```typescript
// 3. 创建路由器
const router = createRouter({
    history: createWebHistory(), // 使用HTML5的history模式
    routes: [
        // 配置路由规则，每一条路由规则是一个对象
        {
            path: "/home",
            component: Home
        },
        {
            path: "/", // 默认路由，访问根路径时跳转到/home
            redirect: "/home"
        }
    ]
});
```

## Pinia

[Pinia 官网](https://pinia.vuejs.org/zh/)，[Pinia 简介](https://pinia.vuejs.org/zh/introduction.html) （vue2 -> vuex ， vue3 -> Pinia）

集中式状态（数据）管理，**Pinia 符合直觉的  Vue.js 状态管理库**，类型安全、可扩展性以及模块化设计。 甚至让你忘记正在使用的是一个状态库。

各个组件件共享数据使用 [Pinia](https://pinia.vuejs.org/zh/) 集中式状态管理。

### 安装 Pinia

```bash
npm i pinia
```

### 使用 pinia

`main.ts` 引入并使用 pinia

```typescript
// 引入 createApp 用来创建应用实例
import {createApp} from 'vue'
// 引入 App 根组件
import App from './App.vue'

// 创建 APP
const app = createApp(App);

// 1. 引入 Pinia
import { createPinia } from 'pinia'
// 2. 创建 Pinia
const pinia = createPinia();
// 3. 使用 pinia ，注意：需要先创建 APP
app.use(pinia);

// 挂载
app.mount('#app')
```

### Pinia 存储、使用数据

#### 存储数据

默认 `src/store` 目录保存 *Pinia* 数据的仓库

`src/store/count.ts` 保存计算相关的数据

```typescript
import { defineStore } from "pinia";
// 选项式写法
export const useCountStore = defineStore('count', {
    // 存储数据的地方
    state() {
        return {
            countSum: 6,
            data: [
                {id: "1", title: "测试"}
            ]
        }
    }
})
```

#### 使用存储数据

`src/components/Count.vue` Vue 计算相关组件

```vue
<template>
    <div class="count">
        <h2>Count 组件，当前计算结果：{{ countStore.countSum }}</h2>
        <!-- 优先转换为数值类型 -->
        <select v-model.number="num">
            <option value="1">1</option>
            <option value="2">2</option>
            <option value="3">3</option>
        </select>
        <button @click="add">加</button>
        <button @click="subtract">减</button>
    </div>
</template>

<script lang="ts" setup name="Count">
    import { ref } from 'vue';
    // 使用 pinia
    import { useCountStore } from '@/store/count'

    const countStore = useCountStore();
    // console.log("@", countStore)
    // // reactive 中的 ref() 会自动拆包，就不用在写 var.value 了
    // console.log("@", countStore.countSum) // 简单写法
    // console.log("@", countStore.$state.countSum) // 复杂写法

    // 选择的数字
    let num = ref(1);

    function add() {
        countStore.countSum += num.value;
    }
    function subtract() {
        countStore.countSum -= num.value;
    }

</script>

<style scoped>
</style>
```

#### 数据修改

```vue
<script lang="ts" setup name="Count">
    import { ref } from 'vue';
    // 使用 pinia
    import { useCountStore } from '@/store/count'

    const countStore = useCountStore();
    // console.log("@", countStore)
    // // reactive 中的 ref() 会自动拆包，就不用在写 var.value 了
    // console.log("@", countStore.countSum)
    // console.log("@", countStore.$state.countSum)

    function add() {
        // 第一种 pinia 数据修改方式，直接使用
        countStore.countSum += num.value;
        // 第二种 pinia 数据批量修改，大量数据修改推荐
        countStore.$patch({
            countSum: 100,
            data: '数据'
        })
    }
</script>
```

第三种方式修改数据，通过 `actions` 函数方式

*pinia* 计算相关数据存储文件 `src/store/count.ts`

```typescript
import { defineStore } from "pinia";

export const useCountStore = defineStore('count', {
    // 存储数据的地方
    state() {
        return {
            countSum: 6
        }
    },
    // actions 内放置的是一个个的方式，用于响应组件中的“动作”
    actions: {
        addFunc(value: number) {
            console.log("addFunc", value)
            // 修改数据
            this.countSum += value;
        },
        subtractionFunc(value: number) {
            console.log('subtraction', value);
            this.countSum -= value;
        }
    }
})
```

*pinia* 使用内置 `actions` 中自定义的动作（函数）修改数据

```vue
<script lang="ts" setup name="Count">
    import { ref } from 'vue';
    // 使用 pinia
    import { useCountStore } from '@/store/count'

    const countStore = useCountStore();

    // 选择的数字
    let num = ref(1);

    function add() {
        // 第三种修改方式，内有复杂业务逻辑处理,使用 actions 函数式
        countStore.addFunc(num.value);
    }
    function subtract() {
        countStore.subtractionFunc(num.value);
    }
</script>
```

#### storeToRefs 优雅使用数据

```vue
<script lang="ts" setup name="Count">
    import { ref } from 'vue';
    // 使用 pinia 存储的数据
    import { useCountStore } from '@/store/count'
    import {storeToRefs} from 'pinia'

    const countStore = useCountStore();
    // 不要用 toRefs 这样会把所有的属性、方法都转为引用了，代价太大
    // storeToRefs 仅把数据转为引用，不会对方发进行 ref 包裹
    let { countSum } = storeToRefs(countStore)

    // 选择的数字
    let num = ref(1);

    function add() {
        countSum.value += num.value;
    }
</script>
```

#### 组合式编写

```typescript
import { defineStore } from "pinia";
import { ref } from "vue";

// 组合式
export const useCountStore = defineStore('count', ()=> {
    // 存储数据的地方
    let countSum = ref(6);

    function addFunc(value: number) {
        console.log("addFunc", value)
        // 修改数据
        countSum.value += value;
    }

    function subtractionFunc(value: number) {
        console.log('subtraction', value);
        countSum.value -= value;
    }

    return { countSum, addFunc, subtractionFunc }
})
```

## 组件通信

### props

`props` 是使用频率最高的一种组件件数据传递（通信）的方式，常用于父、子组件件数据传递。

父传子属性值为非函数，子传父属性值是函数。

**注意：** 尽量不要跨多层级组件件数据传递用 `props`

父组件：

```vue
<template>
    <div class="parent">
        <h2>父组件</h2>
        <h3>汽车： {{ car }}</h3>
        <h3 v-show="toy">子组件给的玩具：{{ toy }}</h3>
        <Child :car="car" :sendToy="getToy"></Child>
    </div>
</template>

<script setup lang="ts" name="Parent">
    import Child from '@/componnet/Child.vue';
    import { ref } from "vue"

    let car = ref("奔驰")
    let toy = ref('')

    // 方法，子组件可以通过此方法给父组件传数据
    function getToy(value: string) {
        console.log('父组件收值', value);
        toy.value = value;
    }
</script>
```

子组件：

```vue
<template>
    <div class="child">
        <h2>子组件</h2>
        <h3>玩具： {{ toy }}</h3>
        <h4>父组件给的 car ： {{ car }}</h4>
        <button @click="sendToy(car)">把玩具给父组件</button>
    </div>
</template>

<script setup lang="ts" name="Child">
    import { ref } from 'vue'
    let toy = ref("机器猫")
    // 声明接收 props
    defineProps(['car', 'sendToy'])
</script>
```

### 自定义事件

通常是子组件给父组件传递数据

父组件：

```vue
<template>
    <div class="parent">
        <h2>父组件</h2>
        <h4 v-show="toy">子组件给的玩具：{{ toy }}</h4>
        <!-- $event 事件对象，给子组件绑定自定义事件，@自定义事件名="自定义事件对应函数" -->
        <Child @custom-evenet="customEvent"></Child>
    </div>
</template>

<script setup lang="ts" name="Parent">
    import Child from '@/componnet/Child.vue';
    import { ref } from "vue"
    let toy = ref('')
    function customEvent(value: string) {
        console.log("自定义事件", value)
        toy.value = value;
    }
</script>
```

子组件：

```vue
<template>
    <div class="child">
        <h2>子组件</h2>
        <h3>玩具： {{ toy }}</h3>
        <button @click="emit('custom-evenet', toy)">点我触发自定义事件</button>
    </div>
</template>

<script setup lang="ts" name="Child">
    import { ref } from 'vue'
    let toy = ref("机器猫")
    // 声明事件
    const emit = defineEmits([ 'custom-evenet' ]);
</script>
```

### mitt

支持任意组件间通信

**注意：** 在组件卸载时需要解绑 `emitter` 绑定事件。

安装 mitt ： `npm i mitt`

`src/utils/emitter.ts`

```typescript
// 引入 mitt
import mitt from 'mitt'
// 调用 mitt 得到 emitter，emitter 能绑定事件、触发事件
const emitter = mitt()

// 绑定事件
emitter.on('testCustomEvent', () => {
    console.log("testCustomEvent 被调用了")
})
// 触发事件
emitter.emit('testCustomEvent')
// 解绑事件
emitter.off('testCustomEvent')
// 清空事件
emitter.all.clear();

// 暴露 emitter
export default emitter
```

父组件

```vue
<template>
    <div class="parent">
        <h2>父组件</h2>
        <h4 v-show="toy">子组件给的玩具：{{ toy }}</h4>
    </div>
</template>

<script setup lang="ts" name="Parent">
    import Child from '@/componnet/Child.vue';
    import { ref, onUnmounted } from "vue"
    import emitter from '@/utils/emitter';
    let toy = ref('')
    // 接收数据方绑定事件
    emitter.on('send-toy', (value: any) => {
        console.log('接收值', value)
        toy.value = value
    });
    // 在组件卸载时注意需要解绑相关事件
    onUnmounted(() => {
        emitter.off('send-toy')
    });
</script>
```

子组件

```vue
<template>
    <div class="child">
        <h2>子组件</h2>
        <h3>玩具： {{ toy }}</h3>
        <button @click="emitter.emit('send-toy', toy)">点我触发自定义事件</button>
    </div>
</template>

<script setup lang="ts" name="Child">
    import { ref } from 'vue'
    import emitter from '@/utils/emitter';
    let toy = ref("机器猫")
</script>
```

### v-module

组件

```vue
<template>
    <div class="parent">
        <!-- v-model 用在普通 html 标签上 -->
        <!-- <input type="text" v-model="toy">
        <input type="text" :value="toy" @input="toy = (<HTMLInputElement>$event.target).value"> -->

        <!-- v-model 用到组件标签上 v-model:自定义双向数据绑定变量名="对象" -->
        <CustomInput v-model="toy" v-model:car="car"></CustomInput>
        <!-- 组件上的 $event 就是传的值，html 标签上的 $event 就是原生 DOM 事件有 targe -->
        <!-- 默认 v-model 写法 -->
        <CustomInput :modelValue="toy" @update:model-value="toy = $event"></CustomInput>
        <!-- 自定义 v-model 写法 -->
        <CustomInput :car="toy" @update:car="toy = $event"></CustomInput>
    </div>
</template>

<script setup lang="ts" name="Parent">
    import CustomInput from '@/componnet/CustomInput.vue';
    let toy = ref('')
    let car = ref('')
</script>
```

自定义组件 `CustomInput.vue`

```vue
<template>
    toy：<input type="text" :value="modelValue" @input="emit('update:model-value', (<HTMLInputElement>$event.target).value)" />
    <br>
    car：<input type="text" :value="car" @input="emit('update:car', (<HTMLInputElement>$event.target).value)" />
</template>

<script setup lang="ts" name="CustomInput">
    defineProps([ 'modelValue', 'car' ])
    const emit = defineEmits(['update:model-value', 'update:car'])
</script>
```

### 插槽

#### 默认插槽

父组件

```vue
<template>
    <div class="parent">
        <h1>父组件</h1>
        <div class="content">
            <Category title="热门游戏列表">
                <ul>
                    <li v-for="g in games" :key="g.id">{{ g.name }}</li>
                </ul>
            </Category>
            <Category title="今日美食城市">
                <img :src="imgUrl" alt="今日美食城市">
            </Category>
            <Category title="今日影视推荐">
                <video :src="videoUrl" controls></video>
            </Category>
        </div>
    </div>
</template>
<script setup lang="ts" name="Parent">
    import Category from '@/componnet/Category.vue';
    import { ref, reactive } from 'vue'
    let games = reactive([
        {id: 'xxx', name: "王者荣耀"},
        {id: 'xxx2', name: "炉石传说"},
        {id: 'xxx3', name: "英雄联盟"},
        {id: 'xxx3', name: "斗罗大陆"}
    ])
    let imgUrl = ref('https://imgs.699pic.com/images/501/406/207.jpg!seo.v1')
    let videoUrl = ref('https://imdb-video.media-imdb.com/vi504668441/1434659607842-pgv4ql-1564507587273.mp4?Expires=1759039630&Signature=WKtJXSVKf05MaBCnfPDOw7w4B5m3JPCNA4RIOP4QzSvhonk4Y0pkYrVKB0ET2bms3zBib8TWlZNF-ovQL6MeuheWicl~kLwNBS98KdBh0WykHkvkUlHXr5w0ADNIsy15bSeo1mDBWn9Z~LvdGQNu9tYMGL~NdSf9VnJxD1Sgi~YlLS~t1atX5TjIH8WHY-T2glUOIOYD7EVlHv43dIHBkM8NPLNhI9JehUSCxqv0oF3MyZuoxsRzVpy7106sD1ApV5v~sFt3HgjNPQCe94T4gzf4m82N9P2fSziuseUIsHlA4-6ADAarQTSer-ZJxwTz20TvpMuku40OWPeAj7LvHA__&Key-Pair-Id=APKAIFLZBVQZ24NQH3KA')
</script>
<style scoped>
    .parent {
        background-color: rgb(165, 164, 164);
        padding: 20px;
        border-radius: 10px;
    }
    .content {
        display: flex;
        justify-content: space-evenly;
    }
    img,video {
        width: 100%;
    }
</style>
```

子组件，默认插槽使用，默认插槽的名称默认就是 `default`，通常忽略不写。

```vue
<template>
    <div class="category">
        <h2>{{ title }}</h2>
        <slot>默认内容</slot>
    </div>
</template>

<script setup lang="ts" name="Category">
    import { defineProps } from 'vue';
    defineProps(["title"]);
</script>

<style scoped>
    .category {
        background-color: skyblue;
        border-radius: 10px;
        box-shadow: 0 0 10px;
        padding: 10px;
        width: 200px;
        height: 300px;
    }
    h2 {
        background-color: orange;
        text-align: center;
    }
</style>
```

#### 具名插槽

具名插槽就是在默认插槽写法上添加 `name` 属性，指定那些模版放到指定的插槽中。

父组件，往插槽中填写内容

```vue
<template>
    <div class="parent">
        <h1>父组件</h1>
        <div class="content">
            <Category>
                <template v-slot:title>
                    <h1>热门游戏列表</h1>
                </template>
                <template v-slot:content>
                     <ul>
                        <li v-for="g in games" :key="g.id">{{ g.name }}</li>
                    </ul>
                </template>
            </Category>
        </div>
    </div>
</template>
```

子组件，插槽定义

```vue
<template>
    <div class="category">
        <slot name="title">默认标题</slot>
        <slot name="content">默认内容</slot>
    </div>
</template>
```

#### 作用域插槽

子组件把数据给父组件使用，通过 `<slot>` 传递数据给父组件使用

父组件

```vue
<template>
    <div class="parent">
        <h1>父组件</h1>
        <div class="content">
            <Category>
                <template v-slot:tip="params">
                    <div>这个是 DIV 展示 tip ： {{ params.tip }}</div>
                </template>
            </Category>
            <Category>
                <template v-slot:tip="{tip}">
					<!-- 直接解构数据，不用在使用变量 . 使用 -->
                    <div class="tip">今日美食城市 tip ： {{ tip }}</div>
                </template>
            </Category>
        </div>
    </div>
</template>
```

子组件

```vue
<template>
    <div class="category">
        <!-- :tip="tip" 把 tip 数据给父组件使用，父组件接收变量名为 tip -->
        <slot name="tip" :tip="tip">默认提示</slot>
    </div>
</template>
<script setup lang="ts" name="Category">
    import { ref, reactive } from 'vue'
    let tip = ref('这个是作用域插槽')
</script>
```

