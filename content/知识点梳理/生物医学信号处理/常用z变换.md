**右边序列**  
- $\delta[n] \quad \leftrightarrow \quad 1$，ROC：全 $z$ 平面  
- $u[n] \quad \leftrightarrow \quad \frac{z}{z-1}$，ROC：$|z|>1$  
- $a^n u[n] \quad \leftrightarrow \quad \frac{z}{z-a}$，ROC：$|z|>|a|$  
- $n a^n u[n] \quad \leftrightarrow \quad \frac{az}{(z-a)^2}$，ROC：$|z|>|a|$  
- $n u[n] \quad \leftrightarrow \quad \frac{z}{(z-1)^2}$，ROC：$|z|>1$  
- $\cos(\omega_0 n) u[n] \quad \leftrightarrow \quad \frac{z(z-\cos\omega_0)}{z^2-2z\cos\omega_0+1}$，ROC：$|z|>1$  
- $\sin(\omega_0 n) u[n] \quad \leftrightarrow \quad \frac{z\sin\omega_0}{z^2-2z\cos\omega_0+1}$，ROC：$|z|>1$  
- $r^n \cos(\omega_0 n) u[n] \quad \leftrightarrow \quad \frac{z(z-r\cos\omega_0)}{z^2-2rz\cos\omega_0+r^2}$，ROC：$|z|>r$  
- $r^n \sin(\omega_0 n) u[n] \quad \leftrightarrow \quad \frac{z r \sin\omega_0}{z^2-2rz\cos\omega_0+r^2}$，ROC：$|z|>r$

**左边序列**  
- $-a^n u[-n-1] \quad \leftrightarrow \quad \frac{z}{z-a}$，ROC：$|z|<|a|$  
- $-u[-n-1] \quad \leftrightarrow \quad \frac{z}{z-1}$，ROC：$|z|<1$

**双边序列**  
- $a^n u[n] - b^n u[-n-1] \; (|a|<|b|) \quad \leftrightarrow \quad \frac{z}{z-a} - \frac{z}{z-b}$，ROC：$|a|<|z|<|b|$

以下是 z 变换的主要性质。设：

- $x[n] \stackrel{\mathcal{Z}}{\longleftrightarrow} X(z)$，ROC = $R_x$
- $y[n] \stackrel{\mathcal{Z}}{\longleftrightarrow} Y(z)$，ROC = $R_y$
- $a, b$ 为常数，$n_0 > 0$ 为正整数。

---

### 1. 线性
$$
a x[n] + b y[n] \quad\stackrel{\mathcal{Z}}{\longleftrightarrow}\quad a X(z) + b Y(z)
$$

$$
\text{ROC} \supseteq R_x \cap R_y
$$


---

### 2. 时移（双边 z 变换）
$$
x[n - n_0] \quad\stackrel{\mathcal{Z}}{\longleftrightarrow}\quad z^{-n_0} X(z)
$$

ROC 可能除去 $z=0$（若 $n_0>0$）或 $z=\infty$（若 $n_0<0$），基本与原 ROC 相同。

**单边 z 变换的时移（用于因果序列初值问题）：**
- 右移（$n_0>0$）：
$$
x[n-n_0]u[n] \quad\stackrel{\mathcal{Z}}{\longleftrightarrow}\quad z^{-n_0} X(z) + \sum_{k=1}^{n_0} x[-k] z^{-(n_0-k+1)}
$$

- 左移（$n_0>0$）：
$$
x[n+n_0]u[n] \quad\stackrel{\mathcal{Z}}{\longleftrightarrow}\quad z^{n_0} X(z) - \sum_{k=0}^{n_0-1} x[k] z^{n_0-k}
$$


---

### 3. 频移（调制）
$$
a^n x[n] \quad\stackrel{\mathcal{Z}}{\longleftrightarrow}\quad X\left(\frac{z}{a}\right)
$$

$$
\text{ROC} = |a| R_x \quad (\text{即原 ROC 乘以 } |a|)
$$


---

### 4. 指数加权（频域尺度）
$$
e^{j\omega_0 n} x[n] \quad\stackrel{\mathcal{Z}}{\longleftrightarrow}\quad X\left(e^{-j\omega_0} z\right)
$$

$$
\text{ROC} = R_x \quad (\text{旋转不变})
$$


---

### 5. 时间反转
$$
x[-n] \quad\stackrel{\mathcal{Z}}{\longleftrightarrow}\quad X(z^{-1})
$$

$$
\text{ROC} = \frac{1}{R_x} \quad (\text{取倒数})
$$


---

### 6. 时间尺度（抽取/内插）– 仅对整数倍
- **抽取**（$k>0$ 整数，$x_k[n]=x[kn]$）无简单封闭形式，通常不列出。
- **内插**（上采样）：若定义 $x_{(m)}[n] = x[n/m]$ 当 $n$ 为 $m$ 的整数倍，否则 0，则
$$
x_{(m)}[n] \quad\stackrel{\mathcal{Z}}{\longleftrightarrow}\quad X(z^m)
$$

  ROC 变为 $R_x^{1/m}$（即原 ROC 的 $m$ 次方根）。

---

### 7. 微分（z 域求导）
$$
n x[n] \quad\stackrel{\mathcal{Z}}{\longleftrightarrow}\quad -z \frac{d X(z)}{dz}
$$

$$
\text{ROC} = R_x \quad (\text{可能除去 } z=0, \infty)
$$


推广：
$$
n^k x[n] \quad\stackrel{\mathcal{Z}}{\longleftrightarrow}\quad \left(-z \frac{d}{dz}\right)^{\!k} X(z)
$$


---

### 8. 卷积（时域卷积）
$$
x[n] * y[n] \quad\stackrel{\mathcal{Z}}{\longleftrightarrow}\quad X(z) Y(z)
$$

$$
\text{ROC} \supseteq R_x \cap R_y
$$


---

### 9. 乘积（z 域卷积，复卷积）
$$
x[n] y[n] \quad\stackrel{\mathcal{Z}}{\longleftrightarrow}\quad \frac{1}{2\pi j} \oint_{C} X(v) \, Y\left(\frac{z}{v}\right) v^{-1} dv
$$

一般不要求记忆，常用于调制分析。

---

### 10. 初值定理（适用于因果序列，$x[n]=0,\ n<0$）
$$
x[0] = \lim_{z\to\infty} X(z)
$$


---

### 11. 终值定理（适用于因果序列，且 $(z-1)X(z)$ 在单位圆内及单位圆上解析）
$$
\lim_{n\to\infty} x[n] = \lim_{z\to 1} (z-1) X(z)
$$


---

### 12. 帕塞瓦尔定理（z 域能量关系）
对于共轭对称序列（实序列常遇）：
$$
\sum_{n=-\infty}^{\infty} x[n] y^*[n] = \frac{1}{2\pi j} \oint_C X(z) Y^*(1/z^*) z^{-1} dz
$$

当 $y[n]=x[n]$ 且单位圆在 ROC 内时：
$$
\sum_{n=-\infty}^{\infty} |x[n]|^2 = \frac{1}{2\pi} \int_{-\pi}^{\pi} |X(e^{j\omega})|^2 d\omega
$$


---

### 13. 共轭
$$
x^*[n] \quad\stackrel{\mathcal{Z}}{\longleftrightarrow}\quad X^*(z^*)
$$

ROC 不变。

---

### 14. 实偶/实奇对称性质（对实序列）
若 $x[n]$ 为实序列，则 $X(z) = X^*(z^*)$，且零极点共轭成对。

---

如果需要完整的性质推导示例或针对特定性质（如单边时移、初值终值例题）进一步说明，请告知。