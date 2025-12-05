#import "template.typ": *
#import "@preview/theorion:0.3.3": *
#import "@preview/subpar:0.2.2"
// #import cosmos.fancy: *
// #import cosmos.rainbow: *
#import cosmos.clouds: *
#show: show-theorion

#set math.equation(numbering: "(1)", supplement: none)
#show math.equation: it => {
  if it.block and not it.has("label") [
    #counter(math.equation).update(v => v - 1)
    #math.equation(it.body, block: true, numbering: none)#label("-")
  ] else {
    it
  }  
}

#let date = datetime.today().display("[month repr:long] [day], [year]")

#set page(
  header: context {
    if counter(page).get().first() > 1 [
    // #text(font: "Cantarell", weight: "extrabold", fill: rgb("#db1a0c"))[TU/e]
    #box(image("images/tue-logo.png", height: 10pt))
    #h(1fr)  
    Bachelor final project
    ]
  },
  footer: context {
    if counter(page).get().first() > 1 [
      #align(center)[#context counter(page).get().first()]
    ]
  }
)

// Modify some arguments, which can be overwritten in the template call
// #page-args.insert("numbering", "1/1")
#text-args-title.insert("size", 2em)
#text-args-title.insert("fill", black)
#text-args-authors.insert("size", 12pt)

#show: template.with(
  title: text(font: "Cantarell", weight: "bold")[Sparse geometric representation of images \ using Gaussian splatting] + text(14pt, black)[\ (Bachelor thesis)],
  authors: (
    (name: "Victor Klomp (Author)"),
    (name: "Bart M.N. Smets (Supervisor)"),
    (name: "Finn M. Sherry (Supervisor)")
  ),
  lines: false,
  // affiliations: (
  //   (id: 1, name: "Affiliation 1, Address 1"),
  //   (id: 2, name: "Affiliation 2, Address 2"),
  //   (id: "*", name: "Corresponding author")
  // ),
  date: date + text(10pt, black)[\ Technical university of Eindhoven],
  heading-color: rgb("#c92127"),
  link-color: rgb("#185693"),
  // Insert your abstract after the colon, wrapped in brackets.
  // Example: `abstract: [This is my abstract...]`
  abstract: lorem(100),
  // keywords: ("First keyword", "Second keyword", "etc."),
  // AMS: ("65M70", "65M12"),
  // Pass page-args to change page settings
  // page-args: page-args,
  // Pass text-args-authors to change author name text settings
  // text-args-authors: text-args-authors,
  // Pass text-args-title to change title text settings
  // text-args-title: text-args-title,
)

#let SPD = math.op("SPD", limits: false)
#let Aff = math.op("Aff", limits: false)
#let aff = math.op($frak("aff")$, limits: false)
#let GL = math.op("GL", limits: false)
#let gl = math.op($frak("gl")$, limits: false)
#let so = math.op($frak("so")$, limits: false)
#let symm = math.op($frak("sym")$, limits: false)
#let SO = math.op("SO", limits: false)
#let trace = math.op("trace", limits: false)

#let act = sym.gt.tri
#let phi = sym.phi.alt

#let todo-box = note-box.with(
  fill: rgb("#9A6700"),
  title: "Todo",
  icon-name: "gear",
)

\ \ \
#align(center)[
  #image("images/frontpage.png", width: 100pt)
]

#colbreak()

#outline()

#colbreak()
// Setup:
// 1. Introduction
//  1.1 Transformers to train images
//  1.2 Guassian splatting in 3D 
//  1.3 Gaussian splatting for transformers
//  1.4 Gaussian derviatives for higher frequency data
// 2. Theory
//  2.1 Primitive Gaussian & derivatives
//  2.2 Lie group, lie algebras
//  2.3 Parametrization of Aff+
// 3. Methods
//  3.1 Close dive into the rendering function
//  3.2 Loss function
//  3.3 Culling
// 4. Results
//  4.1 Basic results
//  4.2 First and second and high frequency data
//  4.3 Hyperparameter tuning
// 5. Conclusion & future work

= Introduction
In the last few years, AI and machine learning have become increasingly important. We have seen ML applied across several domains, mainly text, image and video, and audio. For image recognition, convolutional neural networks (CNN) have been quite successful. CNNs use convolutional kernels to group pixels together, such that for an 100x100 pixel image, we do not need 10,000 weights to connect each pixel. These networks are designed to extract information from images, such as classification. This has become the defacto standard for image recognition in the past 10 years @Zhao2024 @NIPS2012_c399862d

Recently, another model has become prevalent: the transformer @vaswani2023attentionneed.
Transformer take tokens as inputs, in most cases, these tokens are words. The transformer can predict new tokens, leading to generative models. It was discovered that you can serialize an image into patches of 16x16 pixels and use those as tokens to train transformers successfully @dosovitskiy_image_2021. Initially outperforming "classical" CNNs, later the optimizations in the transformers have been backported to CNN @liu2022convnet2020s. In this thesis however, we will focus on transformers instead of CNNs, specifically the generation of tokens for transformers.

Ideally, we can find a set of tokens that describe an image, similar to how a set of words describes a sentence or text. While text tokens can encode grammatical or contextual information, image tokens should capture geometric information. Currently the 16x16 patches do not contain a lot of geometrical information. This is also described in @dosovitskiy_image_2021, where we can see that attention of a token is mostly on tokens that are on the same row/column axis. This is most likely because of the embedding, instead of the actual relevance of those tokens.

One way to generate such tokens is Gaussian splatting. This has popularized in 2023 and is being used for 3D scene reconstruction @kerbl20233d. By taking multiple pictures and spawning Gaussian blobs in 3D to match each view, resulting in a 3D scene represented by Gaussians. This is done using gradient descent to train the scenes to iteratively better match each image, using L1 and SSIM loss. Recently, Gaussian splatting has also been used in 2D for image representation @zhang_gaussianimage_2025. This works essentially by only taking only one image, and training for that single image. This process works a lot simpler as quite a few complication for 3D do not have to be made anymore. Besides encoding tokens for transformers, 2D Gaussian splatting can also be used in scenarios where encoding is done once and decoding is done multiple times, such as textures for video games. 

Tokenization of Gaussian parameters has already been studied @dong_gaussiantoken_2025. In this thesis we aim to provide more geometric value to these tokens by using Lie theory. Furthermore, we hope to use more complex wavelets to encode more information in a single token. As each token has attention to all other tokens, transformer networks grow exponentionally, limiting the amount of tokens is thus key to smaller networks. We hope to use first and second order derivatives of the Gaussian function to define edges and lines more effeciently than a normal Gaussian can.

= Theory
We are expanding the Gaussian splatting method with an explicit geometric description in terms of a Lie group, as well as using higher order derivatives to more efficiently encode edges and lines.

// We will spawn $n$ initial Gaussians, each of which will represent one token, and each token will have $p$ (tbd) parameters that describe the color values of the Gaussian layers and the geometric properties such as location, rotation, and scale. 

== Gaussian layers
Instead of using just the Gaussian function as is usual in Gaussian splatting, we will also use the first and second order derivatives of the Gaussian function. As defined as

$
 phi_0(x) := e^(-||x||^2) \
 hat(phi)_1 = (dif) / (dif x_1) phi_0 \
 hat(phi)_2 = (dif) / (dif x_1) phi_1 
$

Please note that the choice of variable ($x_1$ or $x_2$) for the derivative does not matter, as the axes are orthogonal and the function can be rotated by $90 deg$ to get the other derivative.

This will give us more complex features to work with. These three Gaussians will be layered in the same location. Below, we can see the derivatives when they are unscaled. 
#todo-box[
 Add color scale
]

#figure(
  image("./images/gaussian_derivatives_unscaled.png", width: 50%),
  caption: [
 Unscaled (f.l.r): Gaussian ($phi_0$), first-order derivative ($hat(phi)_1$) and second-order derivative ($hat(phi)_2$) of a Gaussian.
  ],
)

The idea is that the "zeroth-order" derivative is used as the base color, and that the derivatives are used as accents. The first-order derivative contains a fast drop-off, which could be used for creating a sharp edge, and the second-order derivative contains a sharp bump in the middle; this could be used as lines. 

Layering these as is will not result in a good overlap, however, because the "support" of these functions differs a lot. We can scale the derivatives such that their "support" matches better with the Gaussian. Scaling the first-order by 0.7 and the second-order by 0.5, we get the following Gaussians, which will be layered to create more complex structures.

#figure(
  image("./images/gaussian_derivatives_scaled.png", width: 50%),
  caption: [
 Scaled: Gaussian ($phi_0$), first-order derivative ($phi_1$), and second-order derivative ($phi_2$) of a Gaussian.
  ],
)

Each of these Gaussians has an independent set of color values. $c^(i,j)$, $i$ for each the Gaussian layers, and $j$ for the color channels, totalling 9 values. Each color value is not directly the color that the Gaussian attains, but rather an addition or subtraction in a certain direction for the final color. For each pixel color $p c in [0,1]^3$, we start with a default of $0.5$. This has the advantage that the image is color invertible by multiplying all the color values by $-1$, but also does not introduce an implicit bias to the color black, as opposed to white (or vice versa). Therefore, the color values of the Gaussians can attain any value in $RR$, however, most likely they will be pushed between $[-0.5, 0.5]^3$ as the input image contains only values between $[0, 1]^3$. This will be elaborated on later.

== Lie groups
This component for position, rotation, and scale should ideally be a Lie group. As this means our representation can benefit from all the structure and tools that Lie groups provide.

=== Affine group
Such a group $G$ is defined as follows. 

#definition(title: [The affine group with positive determinants])[
The _2-dimensional, real affine group with positive determinants_ is defined as
$
G =Aff^+(RR^2) := RR^2 times.r GL^+(RR^2)
$
with the group operation given by
$
(x_2,A_2)(x_1,A_1) := (A_2 x_1 + x_2, A_2 A_1)
$
for all $(x_2,A_2), (x_1, A_1) in Aff^+(RR^2)$.
]
Where $GL^+(RR^2)$ is the group of 2-dimensional real linear transformations with positive determinants, i.e. $2 times 2$ matrices with positive determinant. This positive determinant ensures that the transformation does not flip the image, as the Gaussians and their derivatives are symmetric, which is not needed. Furthermore, this also causes the group to consistent of two seperate components which we cannot move between in a continious fashion. Intuitively, you can rotate continously, you cannot flip an image continously. Later, this will also make mathematical sense, when we decompose $GL+(RR^2)$ into a rotational matrix and a positive definite symmetric matrix, which is only possible with a positive determinant.

#lemma[
The unit element of $G$ is $(0, I)$, the inverse of any $(x, A) in G$ is $(-A^(-1)x, A^(-1))$ and the $G$ has a dimension of 6.
]

_Proof:_

Let $(x, A) in G$.

The unit element is $(0, I)$, as
$(x, A)(0, I) = (A 0 + x, A I) = (x, A)$.

The inverse is $(-A^(-1)x, A^(-1))$ as $(x, A)(-A^(-1)x, A^(-1)) = (-A A^(-1)x + x, A A^(-1)) = (0, I)$.

The dimension is trivial.

$qed$

#proposition[
$Aff^+(RR^2)$ is a _Lie group_. 
]

_Proof:_

We will show that $(x,y) mapsto x^(-1) y$ with $x, y in G$ is a smooth map. 

As matrix inverse and multiplication and scalar multiplication and addition are all smooth, we conclude that the map $(x,y) mapsto x^(-1) y$ is also smooth. 

$qed$

The affine group acts on $RR^2$ in the following manner:
$
g act y = (x,A) act y := A y + x
$
for all $y in RR^2$ and $g = (x,A) in Aff^+(RR^2)$.
Similarly, for subsets $S subset RR^2$, we define
$
g act S := { g act y | y in S }
.
$

This allows us to use this Lie group to position points in our image. The next thing to consider is that the Gaussians we use to fill our image are not one point, but a collection of points defined by a function in $RR^2$. Therefore, we will also need to define how this group acts on a function on $RR^2$. This is induced as follows: 

Let $f:RR^2 -> RR$ then we define $g act f : RR^2 -> RR$ by
$
(g act f)(y) := f(g^(-1) act y).
$

// Not sure what this means, so not keeping it in for now
// The Lebesgue measure $mu$ on $RR^2$ is _covariant_ under this action:
// $
// mu((x,A) act S) = det(A) mu(S).
// $
// Where we call $chi (g) := det(A)$ the linear characteristic and so $mu(g act S) = chi(g) mu(S)$.

// #todo-box[
// Show that $chi: Aff^+(RR^2) -> RR$ is a Lie group homomorphism between $Aff^+(RR^2)$ and $(RR_(>0),dot)$.
// ]


// #note-box[
//   Alternatively, we can define $(g act f)(y) := 1/chi(g) f(g^(-1) act y)$, which has the advantage that
//   $
//     integral_(RR^2) f(y) dif y = integral_(RR^2) (g act f)(y) dif y
//   $
//   for all $g in G$.

//   Another option is $(g act f)(y) := 1/sqrt(chi(g)) f(g^(-1) act y)$ then we have
//   $
//   (g act f_1,f_2)_(L^2(RR^2)) = (f_1, g^(-1) act f_2)_(L^2(RR^2))
//   $
//   for all $g in G$ and $f_1,f_2 in L^2(RR^2)$.

//   Something to discuss.
// ]


=== Lie groups & parameter space
This works quite well for positioning the Gaussians in some particular spot. However, to make this match our target image, we will use gradient descent, as will be explained later. This requires the parameters to lie in a vector space. This is not the case by default for the Lie group. This means that when applying gradient descent at the current stage, the parameters could no longer be in the Lie group after gradient descent steps. This means that this parameter has no longer any useful meaning, and cannot be used to position the Gaussian. 

For this reason, we will search for a parameter space, $V$, such that $V$ is a vector space, and there exists a surjective function $psi : V -> G$. We can use this to apply gradient descent on $V$, as this is a vector space, and render the image using $G$. 


=== The Lie algebra $aff(RR^2)$
To solve this issue, we will make use of the Lie algebra. This is the tangent space at the identity of the Lie group. The Lie algebra can map to the Lie group (and vice versa), but is also a vector space.

The Lie algebra of $Aff^+(RR^2)$ is $aff(RR^2) := RR^2 times.r gl(RR^2) equiv RR^2 times.r RR^(2 times 2)$.
Note that we say $aff$ and not $aff^+$; this is because $aff$ is the Lie algebra of both the $Aff^+$ and $Aff$ Lie groups, illustrating that there is not a one-to-one relationship between Lie groups and Lie algebras.

#lemma[
The Lie group $Aff^+(RR^2)$ and Lie algebra $aff(RR^2)$ both have a matrix representation, respectively these are
$
  mat(
 A, x;
 0, 1
  )  "and" 
        mat(
 W, v;
 0, 0
  ).
$
This representation of the Lie group still follows the group operation, by doing the matrix multiplication.
]

_Proof:_

Let $(x_1, A_1), (x_2, A_2) in Aff^+(RR^2)$.

$(x_1, A_1) (x_2, A_2)$ in matrix form is 

$mat(A_1, x_1; 0, 1)mat(A_2, x_2; 0, 1) = mat(A_1 A_2, A_1 x_2 + x_1; 0, 1).$

Converting this back is $(A_1 x_2 + x_1, A_1 A_2)$, which proofs the matrix multiplication is equivalent the group operation.

$qed$


// _Relevancy of the following is not directly clear to me_
// -> In principe nog niet direct relevant
// #quote-box[
// As explained, $aff$ is now a vector space, i.e. $aff(RR^2) tilde.equiv RR^6$.
// In addition to being a vector space it is equipped with an anti-symmetric bilinear map called the _Lie bracket_, which in the case of $aff(RR^2) equiv RR^2 times.r RR^(2 times 2)$ is given by
// $
// [(v_1,W_1),(v_2,W_2)] :=  (W_1 v_2 - W_2 v_1,[W_1,W_2]) = (W_1 v_2 - W_2 v_1, W_1 W_2 - W_2 W_1)
// .
// $
// The Lie bracket is essentially a measure of the non-commutativity of the Lie group, for a commutative Lie group the Lie bracket of its Lie algebra is always zero.
// ]

=== The exponential & logarithmic map

// _The following is a bit unclear to me, especially where the definition of the exponential map comes from_ -> kijk naar boek van Hall
// #quote-box[
Lie groups and Lie algebras are related to each other through the exponential map.
For our case the exponential map $exp_(Aff^+(RR^2)) : aff(RR^2) -> Aff^+(RR^2)$ is given by $exp$.

Doing this for $W$ and $v$ seperately is equivalent to $
exp( (v,W) )
:=
( (integral_0^1 e^(t W) dif t) v, e^W ).
$<eq:affine-exp>

Unfortunately, from @culver1966existence we know that the $Aff^+$ exponential map is not surjective. So we cannot use $aff$ to create every possible Gaussian. Besides the fact that it is not surjective, is the integral also a problem. This means that the function is not a convenient closed formula, but instead requires a lot of computation.


== Kaji-Ochiai parameterization

As we cannot use the default Lie algebra $aff$ from the Lie group $Aff^+$ as $V$, we will need to look a bit further. We adapt the findings from @kaji_concise_2016, where they describe a parameterization of $Aff^+(RR^3)$, where this parameterization has a similar role as the Lie algebra. This parameterization is for a 3D affine transformation; it starts from what is essentially the Lie algebra but constructs a different surjective mapping than the exponential onto the group (but still closely related). We will simplify this parametrization to 2 dimensions. 



// See /* @kaji_concise_2016 */ where the authors describe a parameterization for $Aff^+(RR^3)$ that is suitable for our type of application.
// This parameterization starts from what is essentially the Lie algebra but constructs a different surjective mapping than the exponential onto the group (but still closely related).
// We simplify this parametrization to 2 dimensions.


The Kaij-Ochiai parameterization works by factoring the Lie algebra of $Aff^+(RR^2)$ as per
$
aff(RR^2) 
equiv
RR^2 times so(2) times symm(2)
equiv
RR^2 times RR times RR^3
equiv
RR^6
$
where $RR^2$ encodes the translation generator, $so(2)$ the rotation generator and $symm(2)$ the scale and shearing generator.
Here $so(2)$ is the Lie algebra of $SO(2)$ and is given by the real $2 times 2$ anti-symmetric matrices, and so has only a single degree of freedom:
$
so(2) = { mat(0, -r; r, 0) mid(|) r in RR }.
$
The second vector space $symm(2)$ is the set of (real) symmetric $2 times 2$ matrices, but it is not the Lie algebra of any Lie group since the Lie bracket of two symmetric matrices is not necessarily a symmetric matrix; it is anti-symmetric in fact:
$
[A,B]^T = (A B - B A)^T = B^T A^T - A^T B^T = - (A^T B^T - B^T A^T) = -[A,B]
$
for all $A,B in symm(2)$.

The vector space $symm(2)$ has three degrees of freedom:
$
symm(2) = { mat(s_1, s_3; s_3, s_2) mid(|) s_1,s_2,s_3 in RR }
.
$

// Rotational symmetry

// Dit is mogelijk om te laten zien dat dit werkt door te laten zien dat de Affine groep gemaakt kan worden door (x,y) x exp(rotationmatrix)*exp((s_1, 0; 0, s_2))

// Aff+(2) / Stab(phi) -> R^2 x SPD(2)

// Als we de shearing weghalen, kunnen we dan nog alle Gaussians rendering -> als we de shearing weghalen, kunnen we dan nog RR^2 x SPD(2) genereren. 


// This would result in
// $
//   { mat(s_1, 0; 0, s_2) mid(|) s_1,s_2 in RR }
// $

#definition()[
The parametrization map $phi: RR^2 times RR times RR^3 -> Aff^+(RR^2)$ is given by
$
phi(x,r,s) := ( x, exp mat(0,-r;r,0) exp mat(s_1,s_3;s_3,s_2) ).
$<eq:parametrization-map>
]

The matrix exponentials in the parametrization map @eq:parametrization-map have the following closed formulae
$
  exp_symm (r) = 
  exp mat(0,-r; r,0)
 =
  mat(cos r, -sin r; sin r, cos r)
$
and
// $
//   exp mat(s_1, 0; 0, s_2)
//   &=
//   mat(exp(s_1), 0; 0, exp(s_2))
// $

// or including the shearing
$
  exp_so (s_1, s_2, s_3) = 
  exp mat(s_1, s_3; s_3, s_2)
  &=
 e^((s_1+s_2)/2)
  mat(
    cosh(a) + (s_1-s_2)/(2 a) sinh(a),
 s_3/a sinh(a);
 s_3/a sinh(a),
    cosh(a) + (s_2-s_1)/(2 a) sinh(a)
  )
  \
  &=
 e^((s_1+s_2)/2)
  (cosh(a) mat(1,0;0,1) + sinh(a)/a mat((s_1-s_2)/2, s_3; s_3, (s_2-s_1)/2))
$
where $a := 1/2 sqrt((s_1-s_2)^2 + 4 s_3^2)$.


Note that $det(exp mat(0,-r; r,0)) = 1$ and $det(exp mat(s_1, s_3; s_3, s_2)) = e^(s_1+s_2) > 0$.


Furthermore, we can also look at the inverse of the parameterization.
#definition()[
A locally differentiable inverse $arrow.l(phi): Aff^+(RR^2) -> RR^2 times so(2) times symm(2)$ is given by
$
arrow.l(phi)(x,A) := (x, log(A (A^T A)^(-1/2)) , log(sqrt(A^T A))).
$<eq:local-inverse>
]

This local inverse relies on the _polar decomposition_ of a square matrix @hall2015liegroups[#sym.section 2.5].
Every square matrix $A$ admits a polar decomposition into an orthogonal matrix $R$ and a positive semi-definite matrix $S$ so that $A = R S$.
If $A$ is invertible, which it is in our case, then the polar decomposition is unique and $S$ is positive definite.
The matrices $R$ and $S$ are calculated as per
$
R = A (A^T A)^(-1/2)
" and "
S = (A^T A)^(1/2).
$
Since $A$ is invertible $A^T A$ is symmetric positive definite and so has a unique square root, which is itself symmetric positive definite and hence uniquely invertible.
Clearly $A = R S$ and $S$ is symmetric positive definite, orthogonality of $R$ follows from
$
R^T R
=
(A (A^T A)^(-1/2))^T (A (A^T A)^(-1/2))
=
(A^T A)^(-1/2) (A^T A) (A^T A)^(-1/2) = I.
$

// #note-box[
// Some formulae for computing an inverse (need to verify):
// $
// s_1 + s_2 = log(det(S)) = log(det(A))
// ,
// \
// cosh(a) = 2 e^(-(s_1+s_2)/2) trace(S)
// ,
// \
// s_1 - s_2 = e^(-(s_1+s_2)/2) a / sinh(a) (S_(1,1)-S_(2,2))
// ,
// \
// s_3 = e^(-(s_1+s_2)/2) a / sinh(a) S_(2,1)
// .
// $
// ]


== A note on shearing
Shearing is the changing of the angle of the orthogonal base vectors of the space. No shearing with respect to ${e_1, e_2}$ implies that $A e_1^T A e_2 = 0$. In our case $e_1 := (1, 0)^T$ and $e_2 := (0, 1)^T$. This shearing can have some interesting properties, so we will take a closer look to see if we want this or if we want to exclude this from the Gaussian transformations.

Dissecting the polar decomposition from earlier, we can see that $R in SO(2)$ does rotation, and $S in SPD(2)$ does scaling and this shearing. 

We define $S$ as 
$
 S = mat(s_1, s_3; s_3, s_2)
$.

Then we can see that $s_3$ generates shearing, as when $s_3 = 0$ then we have $(S e_1)^T (S e_2) = (s_1, 0) (0, s_2)^T = 0$. And vice versa, if $s_3 != 0$, then $(S e_1)^T (S e_2) = (s_1, s_3) (s_3, s_2)^T = s_1 s_3 + s_3 s_2 != 0$ as $ s_1, s_2 > 0$, clearly introducing a shear.

We know that the stabilizer of $phi_0$ is $SO(2)$. I.e.
$
  "Stab"_G (phi_0) := { g in G | g act phi_0 = phi_0 } equiv SO(2)
$

Furthermore, we can see that the effect of a shear on a Gaussian can also be generated by a rotation and a scale. I.e., we can remove $s_3$ and still generate all Gaussian configurations.

// #definition[
//   $T := {D | D in SPD(2) "and D is diagonal"}$
// ]

#theorem(title: "Shear generation")[

  For all $A in GL^+ (RR^2)$, there exists a $overline(R) in SO(2)$ and $D in SPD(2)$ which is also diagonal, i.e. $D = mat(e^(s_1), 0; 0, e^(s_2))$, such that $A act phi_0 = overline(R) D act phi_0$.
] <thm:shear-generation>

_Proof:_

// First, we know that any $S in SPD(2)$ can be generated by $R in SO(2)$ and $hat(S) in D$ where $D$ is all diagonal matrices. This is an eigendecomposition, defined as the following $S = R^T hat(S) R$.

We know that $A = R S$, then we can do an Eigendecomposition and decompose $S$ as

$
 S = Q Lambda Q^T.
$

Where $Lambda = mat(lambda_1, 0; 0, lambda_2)$ with $lambda_{1,2}$ as the Eigenvalues from S. $Q in O(2)$, however we can flip the Eigenvalues in the decomposition when $det(Q) = -1$, therefore without loss of generality $Q in SO(2)$.

This means that we get the following.

$
 A act phi_0 = R S act phi_0 = R Q Lambda Q^T act phi_0 = R Q Lambda act (Q^T act phi_0) = R Q Lambda act phi_0.
$

Now we can define $overline(R) := R Q in SO(2)$ and $D := Lambda$.

Thus $A act phi_0 = overline(R) D act phi_0$.
$qed$

#proposition(title: "Polar decomposition ordering")[

 Reversing rotational and scaling in the parametrization of Kaij-Ochiai will remove the geometric properties of $s_3$.
 I.e. 
 $
 A(r, s_1, s_2, 0) = exp mat(0, -r; r, 0) exp mat(s_1, 0; 0, s_2)
 $
 never contains no shearing in ${e_1, e_2}$.
 
 While
 $
 B(r, s_1, s_2, 0) = exp mat(s_1, 0; 0, s_2) exp mat(0, -r; r, 0)
 $
 can contain shearing in ${e_1, e_2}$.

]

_Proof:_

// We will take the basis of the space $e_1$ and $e_2$, these are orthogonal if their inner product is zero. We know the basis is orthogonal by definition, thus $e_1^T e_2 = 0$

We will show that any transformation $A = R S$ with 
$
 R = mat(cos r, - sin r; sin r, cos r)
$ 
and
$
 S = mat(exp(s 1), 0; 0, exp(s 2))
$
applied as $R S x$ results in $e_1 e_2^T = 0$.

We can see this by
$
  (A e_1)^T (A e_2) &= (R S e_1)^T (R S e_2)\
  &= e_1^T S^T R^T R S e_2\
  &= e_1^T S^T S e_2 & "As R is orthogonal"  \
  &= (s_1, 0)^T (0, s_2)\
  &= 0.

  
$

It is also true that for $B = S R$, applying $S R x$ in the other order can result in shearing; we will show this with an example.

Define 
$
 S = mat(1, 0; 0, 2)\
$
and
$
 R = mat(sqrt(2)/2, sqrt(2)/2; -sqrt(2)/2, sqrt(2)/2).
$

Now clearly 
$(S R e_1)^T (S R e_2) = - 3/2 != 0$

$qed$

And thus we can see that the parametrization is still surjective with $s_3 = 0$. We can therefore remove this in the parameter space $V equiv RR^5$. We can still map this using $psi$, however, this will no longer map to $Aff^+$, but a subset of that where there exists no shearing. This subset is not a group.

#corollary[

 Define $T subset GL^+(RR^2)$. $T := {A in GL^+(RR^2) | (A e_1)^T A e_2 = 0}$. Then T is not a group.
]

// _Proof:_

// Take $R$ and $S$, which are each clearly in this subset that contains no shearing. However, as we showed before, $S R$ does contain shearing. 
// Thus, not in this subset; therefore, the subset is not a group.

// $qed$

// This results in the positive semi-definite scaling matrix $S$ being applied before the orthogonal rotational matrix $R$.

Intuitively, the previous results make sense as the rotational symmetry of $phi_0$ makes it such that the basis choice ${e_1, e_2}$ is arbitrary and has no dependency on anything else. For $phi_1$ and $phi_2$, this choice is relevant, as we already take the derivative in one of these directions. Shearing will add a unique property to these. Below is an example of the concept of shear in $phi_0$ being generated without $s_3$ or fully with $s_3$, and the effects this has on $phi_1$ and $phi_2$.

#figure(
  image("./images/scale-rotate_vs_shear.png", width: 50%),
  caption: [
 Left: Shearing via scale & rotate, $s_3=0$ | Right: Shearing via setting $s_3$
  ]
)

While this is not exactly the same, and for $phi_{1,2}$ parameterization with $s_3=0$ is no longer surjective, however, removing this property would give us some better analysis on the anisotropy#footnote[Anisotropy is how "stretched" an ellipsoid, or in our case a Gaussian, is. We will see later why this is useful] of a Gaussian, as the anisotropy is now uniquely generated by the scaling parameters. However, we will need to do some experiments if the shear property has a significant impact on the first and second derivatives. 

= Methods
We will look at the methods that we will be using to actually create the Gaussians representations. 

== Rendering function
// For $x in RR^2$ the Gaussian value is defined as $phi(x) = exp(-norm(x))$.

The target image we want to approximate is defined as $f(x) : RR^2 -> RR^3$.

The final image that is generated from the parameters is defined by

$
hat(f)(x) = sum_(k = 0)^n sum_(i)^3 c_k^(i) (g_k act phi.alt)(x) = sum_(k = 0)^n sum_(i)^3 c_k^(i) (psi(v_k) act phi)(x)
$

// Where $c equiv RR^9$ and $v equiv RR^5$ or $v equiv RR^6$ depending on the inclusion of the shearing parameter 

// The group actions are defined by for $g in Aff^+(2), y in RR^2$ then $g act y = (A, x) act y := A y+ x$

To find the optimal parameters $c$ and $v$, we will use gradient descent as explained earlier. For this, we will define a score, called a loss, that determines how well a set of parameters represents the image. Taking steps downwards of the gradient will find us a local minimum. Using extra methods such as optimizers, scheduler, and modifying the loss, we will make sure that minimum found is as close to the global minimum as possible.

// $G = "Aff"^+ (2)$

// $psi : V -> G$

// $psi(L, X, Y) = (L, exp(X) exp(Y))$

// $X = mat(0, b;
// - b, 0)$

// then 

// $exp(X) = mat(cos(b), sin(b);
// - sin(b), cos(b))$

== Culling<culling>
As we want to decrease the number of Gaussians that we save, we will remove the Gaussians based on their parameters. This process we will call culling. The most obvious is that we would like to remove Gaussians where the color values are negligibly small for all Gaussian layers. Formalized by 
$
sum_j^3 abs(c^(1,j)) <= 0.05 and sum_j^3 abs(c^(2,j)) <= 0.05 and sum_j^3 abs(c^(3,j)) <= 0.05.
$

The other criterion is again the anisotropy of the Gaussian, as mentioned earlier. Formally, we do this by removing all Gaussians where
$
 s 1 + s 2 <= -7.5.
$

The problem is that these Gaussians are visible, so doing this culling after all training is done would leave some gaps in the image. Therefore, we do this on 80% of the training, thus giving the gradient descent still some iterations to recover and fill the gaps.

= Results
To put this into practice, we use pytorch to make use of CUDA kernels and speed up the rendering. The source code is available at (). The images are constrained to 1:1 to ease the implementation; the theory can be easily scaled to any ratio. The resolution can differ, depending on the input. For the experiments, mostly 100x100 resolutions are used, as this is a limitation of the physical hardware on which the tests were run. 

The hardware used is an `Intel(R) Core(TM) i7-10750H (12) @ z` and `NVIDIA Quadro T1000 Mobile`; on this hardware, training took between 1 minute and 5 minutes. However, this is not a goal of the project.

In this section, we will discuss the results and adaptations we have made based on the findings. We will first present the final product, which includes all the adaptations, which we will use as our base performance to compare against. 


#subpar.grid(
  columns: (1fr, 1fr),
  caption: [Comparing the original image against the base representation. The base representation uses 1500 Gaussians, ],
  figure(
    image("./images/castle_original.png", width: 100%),
    caption: [
 Original castle image
    ],
  ),
  figure(
    image("./images/castle_base.png", width: 100%),
    caption: [
 Base performance of the representation
    ],
  ),
)


== Initalization
For the initialization, we use a hyperparameter for the number of Gaussians that will be spawned. The color parameters of $phi_0$ will be initialized with a normal distribution $N(0,1)$, for $phi_1$ and $phi_2$, this is $N(0,0.1)$. This prevents the first and second orders from being too active. The position of the Gaussians is also initialized with $N(0,1)$. The scaling parameters are also generated with $N(0,1)$ but immediately shifted down by $-4$. If this is not done, the Gaussians will overlap too much and fight against each other, resulting in streaks. This can be seen below.

#subpar.grid(
  columns: (1fr, 1fr, 1fr),
  rows: (auto),
  gutter: 10pt,
  align: top,
  caption: [Comparing the different intialization techniques. Both representation use 1500 Gaussians, 100x100.],
  figure(
    image("./images/castle_original.png", width: 100%),
    caption: [
 Original castle image
    ],
  ),
  figure(
    image("./images/castle_base.png", width: 100%),
    caption: [
 Base performance of the representation
    ],
  ),
  figure(
    image("./images/castle_big_init.png", width: 100%),
    caption: [
 Representation with unscaled initialization
    ],
  ),
)

== Gradient descent
As mentioned earlier we use gradient descent. For this we need a loss function. This loss functions consists of a few different components. Most importantly, the $L_1$ loss, formally defined as $||f-hat(f)||$. Besides this, we will also use the structural similarity index measure (SSIM). These will be weighed with $lambda$. The total loss for how well the image looks will be
$L_"image" = lambda||f - hat(f)|| + (1 - lambda) * (1 - text("SSIM")(f, hat(f))) $. The $L_1$ loss has a big focus on individual pixel differences, while this is useful, this might overfit on certain pixel. SSIM on the otherhand focus on differences on a structural level, looking more at luminance and constrast. Combining these two has been done in similiar image representation projects, and work here again. 

#todo-box[
  Possible: add some images to back this up. Perhaps also that the loss is more "convex" (i.e. doesnt go up, which was the case when only using L1 loss). Although I have no good reasoning for why this happens. 
]

== Artifacts<artifacts>
Besides the actual representation, we have two other things that we want to discourage to prevent the generation of invisible or unwanted artifacts. As gradient descent tries to find the minimum of the loss, we can put things in the loss to discourage certain behavior. First of all, we want to limit the anisotropy, to make sure Gaussians do not become stretched out, but stay fairly round. Furthermore, we also do not want Gaussians to become too small; to be exact, they must not be smaller than a pixel, as this will make them hidden while rendering, but they still contain information in the final embedding. Both of these are already being prevented in @culling, culling, but to push Gaussians in the right direction before fully being removed, we also want to put this in the loss.

The effects of small gaussians is not directly apparent, seemingly the performance is roughly similiar.

#subpar.grid(
  columns: (1fr, 1fr, 1fr),
  rows: (auto),
  gutter: 10pt,
  align: top,
  caption: [Comparing the size penalty, both representations are started with 1500 Gaussians, 100x100. ],
  figure(
    image("./images/castle_original.png", width: 100%),
    caption: [
 Original castle image
    ],
  ),
  figure(
    image("./images/castle_base.png", width: 100%),
    caption: [
 Base performance of the representation. \ SSIM: 0.0418
    ],
  ),
  figure(
    image("./images/castle_no_size_no_culling.png", width: 100%),
    caption: [
 No sizing in loss, no culling. \ SSIM: 0.0471
    ],
  ),
)

However when rendering the representations upscaled, the difference becomes apparant. Both images are trained in a 100x100 resolution, but the final render is upscaled to 150x150.

#subpar.grid(
  columns: (1fr, 1fr),
  rows: (auto),
  gutter: 10pt,
  align: top,
  caption: [Comparing the upscaled renders of the representation. Not penalizing the size of the Gaussian clearly creates hidden artifacts],
  figure(
    image("./images/castle_base_upscaled.png", width: 100%),
    caption: [
 Base performance of the representation, upscaled to 150x150.
    ],
  ),
  figure(
    image("./images/castle_no_size_no_culling_upscaled.png", width: 100%),
    caption: [
 No sizing in loss, upscaled to 150x150.
    ],
  ),
)

You will see the artifacts in the right image. These are not visible in the 100x100, as they are smaller than a pixel in the 100x100 render. This comes from the fact that the representation is infinitely detailed, but the rendering is a sampling of that representation. For each pixel, instead of the average over the whole pixel, only a specific spot within the pixel is picked. Taking the average is computationally expensive, and only shifts the same problem to the smaller level. These small Gaussians do influence the sample spots of the pixels, so removing them is not an option. This effect is also showcased in @subpixel-sampling.

#subpar.grid(
  columns: (1fr, 1fr),
  rows: (auto),
  gutter: 0pt,
  align: top,
  figure(
    image("./images/sampling_example_high.png", width: 100%),
    numbering: none,
    caption: [
      100x100
    ],
  ),
  figure(
    image("./images/sampling_example_low.png", width: 100%),
    numbering: none,
    caption: [
      2x2
    ],
  ),
  caption: [
    The same Gaussian representation, sampled differently. In this implementation, the sampling happens at the bottom left corner. The bright yellow spot is not visible anymore.
  ],
  label: <subpixel-sampling>
)

The problem with these subpixel Gaussians is that they will still contain information in the tokens, to keep these tokens pure and as close to the original image as possible, we want to remove this. 

To already penalize this in the trainig process, we will add the following loss function $L_"sizing" = overline(exp( -(s_1 + s_2) -8)) * lambda_"sizing"$ to the loss. Where $lambda_"sizing"$ determines how much influence this loss functions has. 

The effect of anisotropic Gaussians is fairly similiar, as can be seen below.

#subpar.grid(
  columns: (1fr, 1fr, 1fr),
  rows: (auto),
  gutter: 10pt,
  align: top,
  caption: [The same Gaussian representation, where shearing is not penalized in the loss. In the upscaled version the artifacts are clearly visible. The SSIM is 0.0396],
  figure(
    image("./images/castle_original.png", width: 100%),
    caption: [
 Original castle image
    ],
  ),
  figure(
    image("./images/castle_no_shear_no_culling.png", width: 100%),
    caption: [
 Representation without shearing loss, and no culling at 100x100. 
    ],
  ),
  figure(
    image("./images/castle_no_shear_no_culling_upscaled.png", width: 100%),
    caption: [
 Representation without shearing loss, and no culling, upscaled to 150x150.
    ],
  ),
)

Here we define the anisotropy as 
$L_"anisotropy" = overline(|s_1 + s_2|) * lambda_"anisotropy"$. Because shear is exclusively generated by the size, this is an easy way to penalize for this.

The final loss is then defined as $L = L_"image" + L_"anisotropy" + L_"sizing"$, $lambda_"anisotropy"$ and $lambda_"sizing"$ are both set to 0.1.

As $RR^2 times RR times RR^3$ are all vector spaces, and the loss function is continuous, we can use gradient descent to optimize this. We will use AdamW and a scheduler to further optimize the training process.

== Amount of Gaussians<amount-of-gaussians>
The amount of Gaussians have a significant impact on both the quality of the image and the amount of tokens, but they are inversely related. Finding an optimal is therefore essential, as too much tokens will slow down the training of the model, but quality is needed to train effeciently. This amount is also highly dependent on the resolution of the original image, and nature of the image. Images which a lot of contrast and high frequency data, such as text in an image, require more Gaussians.

The base image we have been using uses 1500 Gaussians for 100x100, below are the effects doubling and halving that

#subpar.grid(
  columns: (1fr, 1fr, 1fr),
  rows: (auto),
  gutter: 10pt,
  align: top,
  caption: [Comparing different starting amount of Gaussians.],
  figure(""),
  figure(
    image("./images/castle_original.png", width: 100%),
    caption: [
 Original castle image
    ],
  ),
  figure(""),
  figure(
    image("./images/castle_low_amount.png", width: 100%),
    caption: [
 Representation with 750 Gaussians initialized  \
*SSIM Loss:* 0.0770\
*L1 Loss:* 0.0186
    ],
  ),
  figure(
    image("./images/castle_base.png", width: 100%),
    caption: [
 Representation with 1500 Gaussians initialized\
 *SSIM Loss:* 0.0429\
*L1 Loss:* 0.0131
    ],
  ),
  figure(
    image("./images/castle_high_amount.png", width: 100%),
    caption: [
 Representation with 3000 Gaussians initialized\
  *SSIM Loss:* 0.0088 \
*L1 Loss:* 0.0056

    ],
  ),
)

Clearly the progression is visible, the representation initalized with 3000 Gaussians is almost identical for the naked eye. An important side not here is that the tokens grow exponentionally in terms of cost of the neural network. 

== Culling
In @culling, we already talked about how we will do the culling. We will also take a short look at how this works in practise. One of the big things that makes a difference is penalizing the size in the loss. If we do not this we get significantly worse results, and also a big reduction in Gaussians @culling-no-sizing. 

#subpar.grid(
  columns: (1fr, 1fr),
  rows: (auto),
  gutter: 0pt,
  align: top,
  figure(
    image("./images/castle_base.png", width: 100%),
    numbering: none,
    caption: [
      Base performance of the representation. Starts with 1500 Gaussians, end with 1417 Gaussians after culling.
    ],
  ),
  figure(
    image("./images/castle_no_size_culling.png", width: 100%),
    numbering: none,
    caption: [
      Representation with culling, but no size in loss. Starts with 1500 Gaussians, end with 632 Gaussians. 
    ],
  ),
  caption: [
    Not penalizing sizing in the loss results in a worse performance after culling. This makes sense as the representation will count too much on small Gaussians during training, which will be removed afterwards. This is especially noticable for the gray areas, where there is a lack of Gaussians providing any color.
  ],
  label: <culling-no-sizing>
)

Furthermore, going back to @amount-of-gaussians, we can compare the start and end Gaussians.

#table(
  columns: (auto, auto, auto),
  inset: 8pt,
  align: center,
  table.header(
    [], [*Start Gaussians*], [*End Gaussians*],
  ),
  "Low amount: ", "750", "731",
  "Normal amount: ", "1500", "1417",
  "High amount: ", "3000", "2827",

)

About 5% of the Gaussians are being removed. Almost all of these Gaussians are being removed based on color, i.e. they provide little to nothing to the color values.

#subpar.grid(
  columns: (1fr, 1fr, 1fr),
  rows: (auto),
  gutter: 10pt,
  align: top,
  caption: [The same Gaussian representation, where shearing is not penalized in the loss. In the upscaled version the artifacts are clearly visible. The SSIM is 0.0396],
  figure(
    image("./images/castle_original.png", width: 100%),
    caption: [
 Original castle image
    ],
  ),
  figure(
    image("./images/castle_base.png", width: 100%),
    caption: [
 Base performance representation\
 *SSIM:* 0.0418
    ],
  ),
  figure(
    image("./images/castle_no_culling_sizing.png", width: 100%),
    caption: [
 Base performance representation but without culling\
 *SSIM:* 0.0350
    ],
  ),
)

While the performance is better in terms of the SSIM, however we see the same issues as in @artifacts.

== Higher order Gaussians
To see the performance and the influence of the higher order Gaussians, we remove the $phi_0$ and only render $phi_{1,2}$. Looking at the previous comparison we can clearly see the lines and edges in the image.

#grid(
  columns: (1fr, 1fr, 1fr),
  rows: (auto),
  gutter: 10pt,
  align: bottom,
  "",
  figure(
    image("./images/castle_original.png", width: 100%),
    caption: [
 Original castle image
    ],
  ),
  "",
  figure(
    image("./images/castle_accent_low_amount.png", width: 100%),
    caption: [
 Accents with 750 Gaussians initialized 
    ],
  ),
  figure(
    image("./images/castle_accent_base.png", width: 100%),
    caption: [
 Accents with 1500 Gaussians initialized
    ],
  ),
  figure(
    image("./images/castle_accent_high_amount.png", width: 100%),
    caption: [
 Accents with 3000 Gaussians initialized
    ],
  ),
)

You can clearly see where the image has more fidelity, and see the outlines of the castle. This effect is a lot stronger with more Gaussians. 

#grid(
  columns: (1fr, 1fr, 1fr),
  rows: (auto),
  gutter: 10pt,
  align: bottom,
  figure(
    image("./images/cars_original.png", width: 100%),
    caption: [
 Original castle image
    ],
  ),
  figure(
    image("./images/cars_accent_base.png", width: 100%),
    caption: [
 Accents with 1500 Gaussians initialized
    ],
  ),
  figure(
    image("./images/cars_accent_high_amount.png", width: 100%),
    caption: [
 Accents with 3000 Gaussians initialized
    ],
  ),
)

On the cars image containing more edges, this effect is more clearly visible.



= Conclusion
In this thesis, we have looked an alternative tokenization of images for transformer models using Lie theory and Gaussian splatting. We noticed that $Aff^+$ provides a good geometric representation of Gaussians. Unfortunately, the canonical vector space parameterization of Lie groups, Lie algebras, are not suitable. Therefore, we have derived an alternative parametrization that can be better used. 

We have also analyzed the effect of shearing on the Gaussians to be able to better analyze the training process. Noticing that the effect of shearing on Gaussians can also be generated by rotation and scaling. This leaves only two sizing parameters which are geometrically easy to interpret, allowing us to penalize this metric. 

Furthermore, more complex wavelets can be used to encode more complex features in images. Specifically, we can use first and second order derivatives of Gaussians to encode edges and lines in an image. In theory this should be able to reduce the amount of Gaussians used in the representation, although this outside of the scope of this thesis.

Finally, we can use metrics of Gaussians to futher generate tokens that provide useful result. Specifically we can make sure that the training process does not abuse the implementation details of the rendering function, such as Gaussians that are subpixel. Furthermore, we can also remove any Gaussians that are not relevant to the final representation, reducing the amount of final Gaussians that are used as tokens.

= Future work
This thesis has mostly been exploratory on various techniques and topics, ideally, we could better compare actual impact on a large dataset of images. For this, more computing power is needed. This would also allow us to compare image and performance at a higher resolution.

Furthermore, the wavelets have been chosen somewhate arbitrary, perhaps there are other configurations of wavelets that can do better representation. This will probably depend heavily on the type of application. Where specific wavelets might be better suited for specific types of images. 

Finally, the representation is ideally tested on an actual transformer to see if the transformer can properly work with our representation. Ideally this is compared against a representation that does not include first and second order derivatives. We suspect that the transformer is able to extract extra information from the higher orders. 


#colbreak()

#bibliography("bibliography.bib", style: "springer-basic-author-date")
