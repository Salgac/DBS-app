class V2::Ov::SubmissionsController < ApplicationController
  $QUERY_VALUES = ["id", "br_court_name", "kind_name", "cin", "registration_date", "corporate_body_name", "br_section", "br_insertion", "text", "street", "postal_code", "city"]
  $ORDER_VALUES = ["asc", "desc"]
  $SUBMISSION_VALUES = ["br_court_name", "kind_name", "cin", "registration_date", "corporate_body_name", "br_section", "br_insertion", "text", "street", "postal_code", "city"]

  #GET v2/ov/submissions
  def index
    #get params
    params.permit(:page, :per_page, :query, :registration_date_gte, :registration_date_lte, :order_by, :order_type)

    page_num = (params[:page]).to_i
    per_page = (params[:per_page]).to_i

    search_q = params[:query]
    gte_date = params[:registration_date_gte]
    lte_date = params[:registration_date_lte]

    order_by = params[:order_by]
    order_type = params[:order_type] || "desc"

    #validate param values - use default if not present or incorrect
    page_num.zero? ? page_num = 1 : nil
    per_page.zero? ? per_page = 10 : nil

    order_by.in?($QUERY_VALUES) ? nil : order_by = "registration_date"
    order_type.in?($ORDER_VALUES) ? nil : order_type = "desc"

    begin
      Date.iso8601(gte_date)
      Date.iso8601(lte_date)
    rescue ArgumentError => e
      gte_date = Date.new(1900, 1, 1).to_s
      lte_date = Date.today().to_s
    end

    #get values and render
    query = OrPodanieIssue.select($SUBMISSION_VALUES)
      .where(registration_date: gte_date..lte_date)
      .order(order_by => order_type)
      .page(page_num).per(per_page)
    search_q.nil? ? nil : query = query.where("corporate_body_name LIKE :s OR cin::text LIKE :s OR city LIKE :s", s: "%#{search_q}%")

    render json: { items: query, metadata: { page: page_num, per_page: per_page, pages: query.total_pages, total: query.total_count } },
           status: 200
  end

  #POST v2/ov/submissions
  def create
  end

  #DELETE v2/ov/submissions/:id
  def destroy
  end

  #GET v2/ov/submissions/:id
  def show
    render json: {}
  end

  #PUT v2/ov/submissions/:id
  def update
  end
end
