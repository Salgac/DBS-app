class V1::CompaniesController < ApplicationController
  $QUERY_VALUES = ["cin", "name", "br_section", "address_line", "last_update"]
  $ORDER_VALUES = ["asc", "desc"]

  #GET v1/companies
  def show
    #get params
    params.permit(:page, :per_page, :query, :last_update_gte, :last_update_lte, :order_by, :order_type)

    page_num = (params[:page] || 1).to_i - 1
    per_page = (params[:per_page] || 10).to_i

    search_q = params[:query]
    gte_date = params[:last_update_gte] || Date.new(1900, 1, 1).to_s
    lte_date = params[:last_update_lte] || Date.today().to_s

    order_by = params[:order_by] || "last_update"
    order_type = params[:order_type] || "desc"

    #validate param values - use default if not present or incorrect
    page_num.negative? ? page_num = 0 : nil
    per_page.zero? ? per_page = 10 : nil

    order_by.in?($QUERY_VALUES) ? nil : order_by = "last_update"
    order_type.in?($ORDER_VALUES) ? nil : order_type = "desc"

    begin
      Date.iso8601(gte_date)
      Date.iso8601(lte_date)
    rescue ArgumentError => e
      gte_date = Date.new(1900, 1, 1).to_s
      lte_date = Date.today().to_s
    end

    #prepare sql string
    date_sql = "WHERE last_update >= '" + gte_date + "' AND last_update <= '" + lte_date + "'"
    search_q.nil? ? search_sql = "" : search_sql = "AND POSITION('" + search_q + "' IN name)>0 OR POSITION('" + search_q + "' IN address_line)>0"
    order_sql = "ORDER BY " + order_by + " " + order_type

    sql = "SELECT * FROM ov.companies 
    " + date_sql + search_sql + order_sql + " 
    LIMIT " + per_page.to_s + " 
    OFFSET " + (page_num * per_page).to_s + ";"

    #get sql data
    response = format_response(ActiveRecord::Base.connection.execute(sql))
    total_num = ActiveRecord::Base.connection.execute("SELECT count(*) FROM ov.companies " + date_sql + search_sql + ";").getvalue(0, 0)

    #render
    render json: { items: response, metadata: { page: page_num + 1, per_page: per_page, pages: total_num / per_page + 1, total: total_num } }, status: 200
  end

  def format_response(args_array)
    tmp_array = []
    args_array.each do |arg|
      tmp = arg.slice(*$QUERY_VALUES)
      tmp_array << tmp
    end
    return tmp_array
  end
end
