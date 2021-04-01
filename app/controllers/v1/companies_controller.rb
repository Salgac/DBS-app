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

    #prepare sql string and variables
    date_sql = "WHERE last_update >= ? AND last_update <= ?"
    sql_var_arr = [gte_date, lte_date]

    search_q.nil? ? search_sql = " " : (search_sql = "AND POSITION(? IN name)>0 OR POSITION(? IN address_line)>0 "; sql_var_arr += [search_q, search_q])

    order_type.eql? "desc" ? order_sql = "ORDER BY coalesce(?) DESC" : order_sql = "ORDER BY coalesce(?) ASC"

    sql_var_arr += [order_by]
    sql_var_arr += [per_page.to_s, (page_num * per_page).to_s]

    sql = "SELECT cin, name, br_section, address_line, last_update,
      (SELECT count(*) FROM ov.or_podanie_issues WHERE cin = companies.cin GROUP BY cin) AS or_podanie_issues_count,
      (SELECT count(*) FROM ov.znizenie_imania_issues WHERE cin = companies.cin GROUP BY cin) AS znizenie_imania_issues_count,
      (SELECT count(*) FROM ov.likvidator_issues WHERE cin = companies.cin GROUP BY cin) AS likvidator_issues_count,
      (SELECT count(*) FROM ov.konkurz_vyrovnanie_issues WHERE cin = companies.cin GROUP BY cin) AS konkurz_vyrovnanie_issues_count,
      (SELECT count(*) FROM ov.konkurz_restrukturalizacia_actors WHERE cin = companies.cin GROUP BY cin) AS konkurz_restrukturalizacia_actors_count
      FROM ov.companies
      " + date_sql + search_sql + order_sql + " 
      LIMIT ? OFFSET ?;"

    #sanitize query
    main_query = ActiveRecord::Base.sanitize_sql_array([sql, *sql_var_arr])
    count_query = ActiveRecord::Base.sanitize_sql_array(["SELECT count(*) FROM ov.companies " + date_sql + search_sql + ";", *sql_var_arr[0...-3]])

    #get sql data
    response = ActiveRecord::Base.connection.execute(main_query)
    total_num = ActiveRecord::Base.connection.execute(count_query).getvalue(0, 0)

    #render
    render json: { items: response, metadata: { page: page_num + 1, per_page: per_page, pages: total_num / per_page + 1, total: total_num } }, status: 200
  end
end
