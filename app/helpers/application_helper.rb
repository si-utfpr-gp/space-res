module ApplicationHelper
  def full_title(page_title = "", base_title = t("app.name"))
    if page_title.nil? || page_title.empty?
      base_title
    else
      "#{page_title} | #{base_title}"
    end
  end

  def sanitize_text(text)
    tags = %w[p br strong em a ul ol li img table tr td th span]
    attributes = %w[href src alt title width height style target class]
    sanitize text, tags: tags, attributes: attributes
  end

  def sanitize_svg(svg)
    tags = %w[
    svg g path rect circle ellipse line polyline polygon
    text tspan defs use linearGradient radialGradient
    stop clipPath mask symbol
  ]

    attributes = %w[
    x y width height cx cy r rx ry d
    fill stroke stroke-width
    stroke-linejoin stroke-linecap
    transform viewBox xmlns xlink:href
    style id class
    text-anchor font-family font-size font-weight
  ]

    sanitize svg, tags: tags, attributes: attributes
  end
end
