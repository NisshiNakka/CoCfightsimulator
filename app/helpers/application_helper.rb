module ApplicationHelper
  def page_title(title = "")
    base_title = "CoC Fight Simulator"
    title.present? ? "#{title} | #{base_title}" : base_title
  end

  def ogp_image_url
    "#{request.base_url}/ogp.jpg"
  end
end
