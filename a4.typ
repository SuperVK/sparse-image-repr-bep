#set page(columns: 2)
#set par(justify: true)
#set text(hyphenate: false)

#show heading : set text(fill: rgb("#c92127"))

#place(
  top + center,
  scope: "parent",
  float: true,
  text(1.4em, weight: "bold", fill: rgb("#c92127"))[
 Sparse geometric representation of images \ using Gaussian splatting \
  ] + text[_Victor Klomp, Bachelor final project_ \ Eindhoven University of Technology, ] + datetime.today().display("[month repr:long], [year]"),
)

== Image classification
Image classification, assigning textual descriptions to images, has advanced rapidly in recent years, becoming increasingly useful in applications like search, accessibility, and automation. We want to improve this by taking inspiration from Large language models (LLMs). LLMs like ChatGPT process text as sequences of tokens (words or word fragments). To apply this approach to images, we need a way to represent images as sequences of visual tokens, similar to words in a sentence. Currently, the most common method is using small patches of an image as tokens, similar to the pieces of a jigsaw puzzle. However, image patches as tokens lack geometric information: rotating an image drastically alters each patch. We need tokens that preserve geometric relationships, preferably with fewer tokens capturing more information. 

Ideally, we can find a set of tokens that describes an image, similar to how a set of words describes a sentence. 

== Gaussian splatting
Gaussian splatting is a technique where a lot of small, adjustable blobs (Gaussian functions) are fitted to an image. This blob can be seen as the left-most yellow spot in @gaussians. This is used a lot in 3D modelling, usually to recreate a 3D scene from multiple images from different angles. This technique can also be used in 2D to recreate various images. Each blob can have a size, rotation, and color, and with about 1500 blobs, we can recreate a 100x100 pixel image. This can be used, e.g., for upscaling images and for compression of textures in video games. We can also use these blobs as tokens to use as input for the image classification model. For this, we will first need to find the correct positions and colors for each Gaussian blob. The final project is specifically about finding such a representation, not yet about using this in an image classification model.

#figure(
  image("./images/gaussian_derivatives_scaled.png", width: 100%),
  caption: [
 Gaussian blobs (f.l.r.): The classical Gaussian, first-order derivative, and second-order derivative of a Gaussian.
  ],
)<gaussians>


== Higher order Gaussians
To be able to encapsulate more information per token, we use the derivatives of the Gaussian blobs. A standard Gaussian blob is round, and thus very good at encapsulating generic information. We will introduce two new functions that specialize in edges and lines (the middle and right-most function in @gaussians).
//This will allow for fewer tokens to encapsulate the same amount of information.

== Results
Our results show that Gaussian blobs effectively recreate images. Higher-order blobs, in particular, excel at capturing edges, suggesting they can represent complex features with fewer tokens.

#figure(
  caption: [Comparing the representation, and also focusing on just the higher orders],
  grid(
    columns: (1fr, 1fr, 1fr),
    rows: (auto),
    gutter: 0pt,
    align: top,
    figure(
      kind: "subfigure-accents-cars",
      numbering: "(a)",
      supplement: "",
      image("./images/cars_original.png", width: 100%),
      caption: [
 Original car image
      ],
    ),
    figure(
      kind: "subfigure-accents-cars",
      numbering: "(a)",
      supplement: "",
      image("./images/cars_high_amount.png", width: 100%),
      caption: [
 Recreation 3000 Gaussians
      ],
    ),
    figure(
      kind: "subfigure-accents-cars",
      numbering: "(a)",
      supplement: "",
      image("./images/cars_accent_high_amount.png", width: 100%),
      caption: [
 Accents 3000 Gaussians
      ],
    ),
  )
)

Reconstruction quality depends a lot on the number of blobs. It is also important to constrain the blobs so that they do not become too stretched out or too small to keep an accurate recreation. This approach paves the way for more efficient image classification models.