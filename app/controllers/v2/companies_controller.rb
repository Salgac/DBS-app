class V2::CompaniesController < ApplicationController
  $QUERY_VALUES = ["cin", "name", "br_section", "address_line", "last_update"]
  $ORDER_VALUES = ["asc", "desc"]

  #GET v2/companies
  def index
    #get params
    params.permit(:page, :per_page, :query, :registration_date_gte, :registration_date_lte, :order_by, :order_type)

    page_num = (params[:page]).to_i
    per_page = (params[:per_page]).to_i

    search_q = params[:query]
    gte_date = params[:registration_date_gte]
    lte_date = params[:registration_date_lte]

    order_by = params[:order_by]
    order_type = params[:order_type]

    #validate param values - use default if not present or incorrect
    page_num.zero? ? page_num = 1 : nil
    per_page.zero? ? per_page = 10 : nil

    order_by.in?($QUERY_VALUES) ? nil : order_by = "last_update"
    order_type.in?($ORDER_VALUES) ? nil : order_type = "desc"

    begin
      Date.iso8601(gte_date)
      Date.iso8601(lte_date)
    rescue ArgumentError => e
      gte_date.nil? ? gte_date = Date.new(1900, 1, 1).to_s : nil
      lte_date.nil? ? lte_date = Date.today().to_s : nil
    end

    #get values
    query = Company.select($QUERY_VALUES)
      .where(last_update: gte_date..lte_date)
      .order(order_by => order_type)
      .page(page_num).per(per_page)
    search_q.nil? ? nil : query = query.where("name LIKE :s OR address_line LIKE :s", s: "%#{search_q}%")

    #calculate counts
    query = query.select(
      "(#{OrPodanieIssue.distinct.count(:cin)}) or_podanie_issues_count",
      "(#{ZnizenieImaniaIssue.distinct.count(:cin)}) znizenie_imania_issues_count",
      "(#{LikvidatorIssue.distinct.count(:cin)}) likvidator_issues_count",
      "(#{KonkurzVyrovnanieIssue.distinct.count(:cin)}) konkurz_vyrovnanie_issues_count",
      "(#{KonkurzRestrukturalizaciaActor.distinct.count(:cin)}) konkurz_restrukturalizacia_actors_count",
    )

    render json: { items: query, metadata: { page: page_num, per_page: per_page, pages: query.total_pages, total: query.total_count } },
           status: 200
  end
end
