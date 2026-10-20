class ApplicationController < ActionController::Base
  PER_PAGE = 50

  private

  # Sets @page and @total_pages from params and total_count, returns a clamped page.
  def current_page(total_count, per_page: PER_PAGE)
    @total_pages = [(total_count / per_page.to_f).ceil, 1].max
    @page = [params[:page].to_i, 1].max
    @page = @total_pages if @page > @total_pages
    @page
  end

  def page_offset(per_page: PER_PAGE)
    (@page - 1) * per_page
  end
end
