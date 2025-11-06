#import "@preview/clean-math-paper:0.2.4": *
#import "@preview/theorion:0.3.3": *
// #import cosmos.fancy: *
// #import cosmos.rainbow: *
#import cosmos.clouds: *
#show: show-theorion

#let date = datetime.today().display("[month repr:long] [day], [year]")

// Modify some arguments, which can be overwritten in the template call
#page-args.insert("numbering", "1/1")
#text-args-title.insert("size", 2em)
#text-args-title.insert("fill", black)
#text-args-authors.insert("size", 12pt)

#show: template.with(
  title: "Sparse representation of images using gaussian splatting",
  authors: (
    (name: "Victor Klomp"),
  ),
  // affiliations: (
  //   (id: 1, name: "Affiliation 1, Address 1"),
  //   (id: 2, name: "Affiliation 2, Address 2"),
  //   (id: "*", name: "Corresponding author")
  // ),
  date: date,
  heading-color: rgb("#ff0000"),
  link-color: rgb("#008002"),
  // Insert your abstract after the colon, wrapped in brackets.
  // Example: `abstract: [This is my abstract...]`
  abstract: lorem(30),
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



// Setup:
// 1. Introduction
//  1.1 Transformers to train images
//  1.2 Guassian splatting in 3D 
// 2. Methods
//  2.1 Primitive gaussian & derivatives
//  2.2 Lie group, lie algebras
//  2.3 Parametrization of Aff+
//  2.4 Close dive into the rendering function
//  2.5 Loss function
//  2.6 Culling
// 3. Results
//  3.1 Basic results
//  3.2 First and second and high frequency data
//  3.3 Hyperparameter tuning

= Introduction
In the last few years, AI and machine learning has become increasingly important. We have seen AI across a few domains, mainly text, image & video and audio. Each of these AI models work by using tokens as inputs for transformers. For text, these tokens are words or letters, however for images & video, defining these tokens is a bit more arbitrary. The most common approach is by taking 16x16 values of pixels, together with 

= Method
We will adapt the 2D gaussian splatting to include extra secondary data. This is the geometric concepts of the image, such as the rotation, scaling and translation. And we will try to incorporate higher frequency data  of the image by using derivatives of the gaussian to be better able to plot edges and lines.

We will spawn $n$ initial gaussians, which will represent one token, and each token will have 7 parameters that describes the color values of the gaussian layers and the location, rotation and scale. 

== Gaussian layers
Instead of using just the gaussian function as is usual in gaussian splatting, we will also use the first and second order derivative of the gaussian function. This will give us more complex features to work with. These three gaussians will be layered in the same location. It does not matter in which dimension we take the derivative, as the result will be perpendicular symmetries of each other. Below we can see the derivatives when they are unscaled. 
#figure(
  image("./images/gaussian_derivatives_unscaled.png", width: 50%),
  caption: [
    Unscaled gaussian, first-order derivative and second-order derivative of a gaussian.
  ],
)

The idea is that the "zeroth-order" derivative is used as the base color, and that the derivatives are used as accents. The first-order derivative contains a fast drop-off, this could be used for creating a sharp edge, and the second order derivative contains a sharp bump in the middle this could be used as lines. 

Layering these as is will not result in a good overlap however, because the support of these functions differs by a lot. We can scale the derivatives such that their support matches better with gaussian. Scaling the first-order by 0.7 and the second-order by 0.5, we get the following gaussians, which will be layered to create more complex structures.

#figure(
  image("./images/gaussian_derivatives_scaled.png", width: 50%),
  caption: [
    Scaled gaussian, first-order derivative and second-order derivative of a gaussian.
  ],
)

Each of these gaussians have an independent color values. Where each color value is not directly the color that the gaussian attains, but rather a push in a certain direction for the final color. For each pixel color $p c in [0,1]^3$, we start with a default of $0.5$. This has the advantage that the image is color invertible by multiplying all the color values by $-1$, but also does not introduce an implicit bias to the color black, as opposed to white (or vice versa). Therefor the color values of the gaussians can attain any value in $RR$, however, most likely they will be pushed between $[-0.5, 0.5]^3$ as  the input image contains only values between $[0, 1]^3$. This will be elaborated on later.

== Lie groups
This component for position, rotation and scale should ideally be a lie group. As this means our representation has geometric properties. 

=== Affine group
Such a group $G$ is defined as the following. 

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
Where $GL^+(RR^2)$ is the group of 2-dimensional real linear transformations with positive determinants, i.e. $2 times 2$ matrices with positive determinant. This positive determinants ensures that the transformation does not flip the image, as the gaussians and their derivatives are symmetric, this is not needed.

#todo-box[
  What are the unit element and the inverse?
  
  What is the dimension of the group?
  
  Prove $Aff^+(RR^2)$ is a _Lie group_.
]

The affine group _acts_ on $RR^2$ in the following manner:
$
g act y = (x,A) act y := A y + x
$
for all $y in RR^2$ and $g = (x,A) in Aff^+(RR^2)$.
Similarly for subsets $S subset RR^2$ we define
$
g act S := { g act y | y in S }
.
$

This allows us to use this lie group to position points in our image. The next thing to consider is that the gaussians we use to fill our image is not one point, but a collection of points defined by a function in $RR^2$. Therefore we will also need to define how this group acts on a function on $RR^2$. This is induced as the following: 

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
This works quite well for positioning the gaussians at once. However, to make this match our target image, we will use gradient descent, as will be explained later. This requires the parameters to be a vector space. This is not the case by default for the Lie group. This means that when applying gradient descent at the current stage, the parameters could no longer be in the Lie group after gradient descent steps. This means that this parameter has no longer any useful meaning, and cannot be used to position the gaussian. 

For this reason, we will search for a parameter space, $V$, such that $V$ is a vector space, and there exists a surjective function $psi : V -> G$. We can use this to apply gradient descent on $V$, as this is a vector space, and render the image using $G$. 


=== The Lie algebra $aff(RR^2)$
To solve this issue, we will make use of the Lie algebra. This is the tangent space at the identity of the Lie group. The Lie algebra can map to the Lie group (and vice versa), but is also a vector space.

The Lie algebra of $Aff^+(RR^2)$ is $aff(RR^2) := RR^2 times.r gl(RR^2) equiv RR^2 times.r RR^(2 times 2)$.
Note that we say $aff$ and not $aff^+$, this is because $aff$ is the Lie algebra of both the $Aff^+$ and $Aff$ Lie groups, illustrating that there is not a one-to-one relationship between Lie groups and Lie algebras.

The lie algebra $aff$ can be represented by the linear transformation $W$ and a translation $v$ seperately. Or they can be put together in one matrix, as 

$
  A = mat(
    W, v;
    0, 0
  )
$

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
Lie groups and Lie algebras are related to each other through the _exponential map_.
For our case the exponential map $exp_(Aff^+(RR^2)) : aff(RR^2) -> Aff^+(RR^2)$ is given by $exp(A)$.

Doing this for $W$ and $v$ seperately is equivalent to $
exp( (v,W) )
:=
( (integral_0^1 e^(t W) dif t) v, e^W ).
$<eq:affine-exp>

Unfortunately, from @culver1966existence we know that matrix multiplication is not surjective. So we cannot use $aff$ to create every possible gaussian. Besides the fact that is not surjective, is the integral also a problem. This means that the function is not a convenient close formula, but instead requires a lot of computation.


== Kaji-Ochiai parameterization

As we cannot use the default Lie algebra $aff$ from the Lie group $Aff^+$ as $V$, we will need to look to a bit further. We adapt the findings from @kaji_concise_2016, where they describe a parameterization for $Aff^+(RR^3)$. This parameterization is for 3D affine transformation, it starts from what is essentially the Lie algebra but constructs a different surjective mapping than the exponential onto the group (but still closely related). We will simplify this parametrization to 2 dimensions. 



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
Here $so(2)$ is the Lie algebra of $SO(2)$ and is given by the real $2 times 2$ anti-symmetric matrices and so has only a single degree of freedom:
$
so(2) = { mat(0, -r; r, 0) mid(|) r in RR }.
$
The second vector space $symm(2)$ is the set of (real) symmetric $2 times 2$ matrices, but it is not the Lie algebra of any Lie group since the Lie bracket of two symmetric matrices is not necessarily a symmetric matrix, it is anti-symmetric in fact:
$
[A,B]^T = (A B - B A)^T = B^T A^T - A^T B^T = - (A^T B^T - B^T A^T) = -[A,B]
$
for all $A,B in symm(n)$.

The vector space $symm(2)$ has three degrees of freedom:
$
symm(2) = { mat(s_1, s_3; s_3, s_2) mid(|) s_1,s_2,s_3 in RR }
.
$

// Rotational symmtry

// Dit is mogelijk om te laten zien dat dit werkt door te laten zien dat de Affine groep gemaakt kan worden door (x,y) x exp(rotationmatrix)*exp((s_1, 0; 0, s_2))

// Aff+(2) / Stab(phi) -> R^2 x SPD(2)

// Als we de shearing weghalen, kunnen we dan nog alle gaussians rendering -> als we de shearing weghalen, kunnen we dan nog RR^2 x SPD(2) genereren. 

Disecting the degrees of freedom, we see that $s_1$ and $s_2$ determine the scaling in each axis. And $s_3$ determines skew. As the gaussian is symmetric in all axis, skew can also be generated by scaling and rotation, making this parameter obsolete. The first and second order gaussians are not symmetric is all axis, so skew does add an unique property here. However, this is removed to be able to analyze the gaussians more effectively in the loss and culling. This will be explained later. We except the removal of skew does not have a big impact. This result in

$
  { mat(s_1, 0; 0, s_2) mid(|) s_1,s_2 in RR }
$

#definition()[
The parametrization map $phi: RR^2 times RR times RR^3 -> Aff^+(RR^2)$ is given by
$
phi(x,r,s) := ( x, exp mat(0,-r;r,0) exp mat(s_1,0;0,s_2) ).
$<eq:parametrization-map>
]

The matrix exponentials in the parametrization map /* @eq:parametrization-map */ have the following closed formulae
$
  exp mat(0,-r; r,0)
  =
  mat(cos r, -sin r; sin r, cos r)
$
and
$
  exp mat(s_1, 0; 0, s_2)
  &=
  mat(exp(s_1), 0; 0, exp(s_2))
$
Note that $det(exp mat(0,-r; r,0)) = 1$ and $det(exp mat(s_1, s_3; s_3, s_2)) = e^(s_1+s_2) > 0$.


_I think this is relevant for gradient descent_
#quote-box[

#definition()[
A locally differentiable inverse $arrow.l(phi): Aff^+(RR^2) -> RR^2 times so(2) times symm(2)$ is given by
$
arrow.l(phi)(x,A) := (x, log(A (A^T A)^(-1/2)) , log(sqrt(A^T A))).
$<eq:local-inverse>
]

This local inverse relies on the _polar decomposition_ of a square matrix /* @hall2015liegroups[#sym.section 2.5]. */
Every square matrix $A$ admits a polar decomposition into an orthogonal matrix $R$ and and a positive semi-definite matrix $S$ so that $A = R S$.
If $A$ is invertible, which it is in our case, then the polar decomposition is unique and $S$ is positive definite.
The matrices $R$ and $S$ are calculated as per
$
R = A (A^T A)^(-1/2)
" and "
S = (A^T A)^(1/2).
$
Since $A$ is invertible $A^T A$ is symmetric positive definite and so has a unique square root which is itself symmetric positive definite and hence uniquely invertible.
Clearly $A = R S$ and $S$ is symmetric positive definite, orthogonality of $R$ follows from
$
R^T R
=
(A (A^T A)^(-1/2))^T (A (A^T A)^(-1/2))
=
(A^T A)^(-1/2) (A^T A) (A^T A)^(-1/2) = I.
$

#note-box[
Some formulae for computing an inverse (need to verify):
$
s_1 + s_2 = log(det(S)) = log(det(A))
,
\
cosh(a) = 2 e^(-(s_1+s_2)/2) trace(S)
,
\
s_1 - s_2 = e^(-(s_1+s_2)/2) a / sinh(a) (S_(1,1)-S_(2,2))
,
\
s_3 = e^(-(s_1+s_2)/2) a / sinh(a) S_(2,1)
.
$
]
]

== Rendering function
For $x in RR^2$ the Gaussian value is defined as $phi(x) = exp(-norm(x))$.

The target image we want to approximate is defined as $f(x) : RR -> RR^2$.

The final image that is generated from the parameters is defined by

$
hat(f)(x) = sum_(i = 0)^n c_i (g_i act phi.alt)(x) = sum_(i = 0)^n c_i (psi(v_i) act phi)(x)
$

// The group actions are defined by for $g in Aff^+(2), y in RR^2$ then $g act y = (A, x) act y := A y+ x$

To find the optimal parameters $c_i$ and $v_i$, we will use gradient descent as explained earlier. For this, we will define a score that determines how well a set of parameters represents the image. We will use two methods to measure how well a representation is. First of all, we will use the $L_1$ norm, in practice, this is the pixel-by-pixel difference of each color channel. Formally defined as $||f-hat(f)||$. Besides this we will also use the structural similarity index measure (SSIM). These will be weighed with $lambda$. The total loss for how well the image looks will be
$L_"image" = lambda||f - hat(f)|| + (1 - lambda) * (1 - text("SSIM")(f, hat(f))) $.

Besides the actual representation, we have two other things that we want to discourage. As gradient descent tries to find the minimum of the loss, we can put things in the loss to discourage certain behavior. First of all, we want to limit the anisotropy, to make sure gaussians do not become stretched out, but stay fairly round. This will prevent artifacts and overfitting. Futhermore, we also do not want gaussians too become too small, to be exact they must not be smaller than a pixel, as this will make them hidden while rendering, but they still contain information. 

We will add two extra components to the loss function, one for the sizing and one for the anisotropy. They are defined as 
$L_"anisotropy" = overline(|s_1 + s_2|) * lambda_"anisotropy"$
and 
$L_"sizing" = overline(exp( -(s_1 + s_2) -8)) * lambda_"sizing"$. Where $lambda_"anisotropy"$ and $lambda_"sizing"$ are how much influence these loss functions have. 

The final loss is then defined as $L = L_"image" + L_"anisotropy" + L_"sizing"$



As $RR^2 times RR times RR^3$ are all vector spaces and the loss function is continuous we can use gradient descent to optimize this. We will use AdamW and a scheduler to futher optimize the trainig process.

$G = "Aff"^+ (2)$

$psi : V -> G$

$psi(L, X, Y) = (L, exp(X) exp(Y))$

$X = mat(0, b;
- b, 0)$

then 

$exp(X) = mat(cos(b), sin(b);
- sin(b), cos(b))$

== Culling
As we want to decrease the amount of gaussians that we save, we will culling the gaussians based on their parameters. The most obvious is that we would like to remove gaussians where the color values are negligible small for all gaussian layers. Formalized by 
$ c_i $


// The template uses #link("https://typst.app/universe/package/i-figured/")[`i-figured`] for labeling equations. Equations will be numbered only if they are labelled. Here is an equation with a label:

// $
//   sum_(k=1)^n k = (n(n+1)) / 2
// $<equation>

// We can reference it by `@eq:label` like this: @eq:equation, i.e., we need to prepend the label with `eq:`. The number of an equation is determined by the section it is in, i.e. the first digit is the section number and the second digit is the equation number within that section.

// Here is an equation without a label:

// $
//   exp(x) = sum_(n=0)^oo (x^n) / n!
// $

// As we can see, it is not numbered.

// = Theorems

// The template uses #link("https://typst.app/universe/package/great-theorems/")[`great-theorems`] for theorems. Here is an example of a theorem:

// #theorem(title: "Example Theorem")[
//   This is an example theorem.
// ]<th:example>
// #proof[
//   This is the proof of the example theorem.
// ]


// We also provide `definition`, `lemma`, `remark`, `example`, and `question`s among others. Here is an example of a definition:

// #definition(title: "Example Definition")[
//   This is an example definition.
// ]

// #question(title: "Custom mathblock?")[
//   How do you define a custom mathblock?
// ]

// #let answer = my-mathblock(
//   blocktitle: "Answer",
//   bodyfmt: text.with(style: "italic"),
// )

// #answer[
//   You can define a custom mathblock like this:
//   ```typst
//   #let answer = my-mathblock(
//     blocktitle: "Answer",
//     bodyfmt: text.with(style: "italic"),
//   )
//   ```
// ]

// Similar as for the equations, the numbering of the theorems is determined by the section they are in. We can reference theorems by `@label` like this: @th:example.

// To get a bibliography, we also add a citation @Cooley65.

// #lorem(50)

// #bibliography("bibliography.bib")

// // Create appendix section
// #show: appendices


// If you have appendices, you can add them after `#show: appendices`. The appendices are started with an empty heading `=` and will be numbered alphabetically. Any appendix can also have different subsections.

== Appendix section

#lorem(100)

#bibliography("bibliography.bib", full: true, style: "springer-basic-author-date")
