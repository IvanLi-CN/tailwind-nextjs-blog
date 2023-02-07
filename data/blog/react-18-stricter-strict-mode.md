---
title: React 18，新的严格模式
date: '2023-02-06'
tags: ['React']
draft: false
summary: 好好的 useMemo、useEffect 居然执行了两次，我明明传入了依赖，为什么会执行两次呢？原来是 React 18 的破坏性改动！
---

之前在开发模式时，一直记得 `useMemo` 在严格模式下不会二次执行， `useEffect` 在有传入 `deps` 时也不会二次执行。而今天我在排下面这段代码时，发现一个要命的事情！

```tsx
const camera = useMemo(/* .. */, []);
const renderer = props; // from parent

const controls = useMemo(
  () => new OrbitControls(camera, renderer.domElement),
  [camera, renderer],
);

useEffect(() => {
  // 同一个 controls 进入两次
  return () => {
    controls.dispose(); // 执行一次，controls 被释放
  };
}, [controls]);
```

`controls` 生成了两个，第一个似乎没用到了，第二个是后续要正常使用的对象，并且进入了 `useEffect` 中，而且进去了两次！
这导致两个严重的问题就是，第一个 `controls` 没有被销毁，第二个 `controls` 被销毁了！
第一个没销毁是内存泄漏，第二个被销毁了导致 `controls` 对象不可用了！

我一度以为是我对 useEffect 特性的记忆出现了偏差，后来我在官方文档翻了半天没啥收获，指到我看见了更新说明里的 [Stricter Strict Mode](https://github.com/facebook/react/blob/main/CHANGELOG.md#1820-june-14-2022:~:text=Stricter%20Strict%20Mode)。

## 新的严格模式

从更新日志可以看到，新的严格模式会自动卸载并再次重新挂载每个组件，这就解释了为什么 `useMemo` 和 `useEffect` 即使在有传入 `deps` 也会多执行一次。

这个特性是破坏性的，会影响之前版本的程序逻辑，所以 React 在[更新说明](https://github.com/facebook/react/blob/main/CHANGELOG.md#1820-june-14-2022:~:text=If%20this%20breaks%20your%20app%2C%20consider%20removing%20Strict%20Mode%20until%20you%20can%20fix%20the%20components%20to%20be%20resilient%20to%20remounting%20with%20existing%20state.)也建议如果旧的应用因为这个出现兼容性问题，建议先关掉 `strictMode`。

### 在 React 18 的测试代码

![React 18 Stricter Strict Mode.png](https://pan.ivanli.cc/api/v3/file/source/2753/React%2018%20Stricter%20Strict%20Mode.png?sign=ARQ8AVTh-NEaeJRypJlVokuUVhocPeaK8n7GRSDwqNw%3D%3A0)

代码：[Code Sandbox](https://codesandbox.io/p/sandbox/clever-cache-pm1oct?file=%2Fsrc%2FApp.tsx&selection=%5B%7B%22endColumn%22%3A20%2C%22endLineNumber%22%3A33%2C%22startColumn%22%3A20%2C%22startLineNumber%22%3A33%7D%5D)

红色是第一次渲染，绿色是第二次渲染。输出日志里淡些的是 React 18 在二次调用时输出的 log 的默认效果，在 React 17 中是被默认隐藏的。蓝色指向的是最终应用在界面上呈现的结果。

我在 V 站上也提出了我的[疑问](https://v2ex.com/t/913595)，根据大佬们的回复，我总结了一下：

1. `useMemo(() => /* */, [])` 执行一此后，以新的严格模式的规则，进行了二次调用，第一次的值作废。
2. `useEffect(() => /* */, [])`执行一此后，以新的严格模式的规则，调用了 `destructor` 后，进行了二次调用。

在第 2 点中，两次 useEffect 都是使用同一个值，是因为严格模式的二次调用按钩子分别执行两次，所以 useMemo 两次的调用都完毕后，得到的值再被 useEffect 执行两次。我调整了一下代码，将测试代码复制了一份在后面，可以看到 “useMemo” 和 “useMemo 2” 先执行了一次，又再执行了一次，然后再到 “useEffect“ 和 “useEffect 2"：
![加倍快乐](https://pan.ivanli.cc/api/v3/file/source/2754/React%2018%20Stricter%20Strict%20Mode%202.png?sign=iYz9KP9uMuccRCesjqoRPKejEoUOj4FZfnBPt8kCXnQ%3D%3A0)

## 结论

`useEffect` 应该独自管理副作用，要做到自己创建，自己销毁。

```tsx
const camera = useMemo(/* .. */, []);
const renderer = props; // from parent

const [controls, setControls] = useState<OrbitControls | null>(null);
useEffect(() => {
  const controls = new OrbitControls(camera, renderer.domElement) // 自己的锅
  setControls(controls);
  return () => {
    controls.dispose(); // 自己背
  };
}, [camera, renderer]);
```

今天深究了一下这个问题，解决方案其实我也知道，但是之前的写法突然以我不理解的方式失效了，还是要较个劲，万一是 React 不规范呢？（狗头
