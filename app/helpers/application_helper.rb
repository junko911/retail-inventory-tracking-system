module ApplicationHelper
  def pagination_nav
    return if @total_pages.blank? || @total_pages <= 1

    content_tag(:p, class: "pagination") do
      parts = ["Page #{@page} of #{@total_pages}"]
      parts << link_to("Previous", yield(@page - 1)) if @page > 1
      parts << link_to("Next", yield(@page + 1)) if @page < @total_pages
      safe_join(parts, " | ")
    end
  end

  def main_nav_item(label, path, controller:)
    if controller_name == controller.to_s
      content_tag(:strong, label)
    else
      link_to(label, path)
    end
  end
end
