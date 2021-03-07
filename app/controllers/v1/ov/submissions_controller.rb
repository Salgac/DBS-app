class V1::Ov::SubmissionsController < ApplicationController
  $QUERY_VALUES = ["id", "br_court_name", "kind_name", "cin", "registration_date", "corporate_body_name", "br_section", "br_insertion", "text", "street", "postal_code", "city"]
  $ORDER_VALUES = ["asc", "desc"]

  #GET v1/ov/submissions
  def show
    #get params
    params.permit(:page, :per_page, :query, :registration_date_gte, :registration_date_lte, :order_by, :order_type)

    page_num = (params[:page] || 1).to_i - 1
    per_page = (params[:per_page] || 10).to_i

    search_q = params[:query]
    gte_date = params[:registration_date_gte] || Date.new(1900, 1, 1).to_s
    lte_date = params[:registration_date_lte] || Date.today().to_s

    order_by = params[:order_by] || "registration_date"
    order_type = params[:order_type] || "desc"

    #validate param values
    page_num.negative? ? (return render_error("wrong/no page_num value", 400)) : nil
    per_page.zero? ? (return render_error("wrong/no per_page value", 400)) : nil

    order_by.in?($QUERY_VALUES) ? nil : (return render_error("wrong order_by value", 400))
    order_type.in?($ORDER_VALUES) ? nil : (return render_error("wrong order_type value", 400))

    begin
      Date.iso8601(gte_date)
      Date.iso8601(lte_date)
    rescue ArgumentError => e
      return render_error(e, 400)
    end

    #prepare sql string
    date_sql = "WHERE registration_date >= '" + gte_date + "' AND registration_date <= '" + lte_date + "'"
    search_q.nil? ? search_sql = "" : search_sql = "AND POSITION('" + search_q + "' IN corporate_body_name)>0 OR POSITION('" + search_q + "' IN cin::text)>0 OR POSITION('" + search_q + "' IN city)>0"

    sql = "SELECT * FROM ov.or_podanie_issues 
    " + date_sql + search_sql + "
    ORDER BY " + order_by + " " + order_type + " 
    LIMIT " + per_page.to_s + " 
    OFFSET " + (page_num * per_page).to_s + ";"

    #get sql data
    response = format_response(ActiveRecord::Base.connection.execute(sql))
    total_num = ActiveRecord::Base.connection.execute("SELECT count(*) FROM ov.or_podanie_issues " + date_sql + search_sql + ";").getvalue(0, 0)

    #render
    render json: { items: response, metadata: { page: page_num + 1, per_page: per_page, pages: total_num / per_page + 1, total: total_num } }, status: 200
  end

  #POST v1/ov/submissions
  def create
    render json: { test: "post" }
  end

  #DELETE v1/ov/submissions
  def destroy
    render json: { test: "delete" }
  end

  #############
  ## HELPERS ##
  #############

  def format_response(args_array)
    tmp_array = []
    args_array.each do |arg|
      tmp = arg.slice(*$QUERY_VALUES)
      tmp_array << tmp
    end
    return tmp_array
  end

  #TODO proper error rendering according to specification
  def render_error(message, status_code)
    render json: { error: { message: message } }, status: status_code
  end
end
