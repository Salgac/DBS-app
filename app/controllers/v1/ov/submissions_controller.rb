class V1::Ov::SubmissionsController < ApplicationController
  $QUERY_VALUES = ["id", "br_court_name", "kind_name", "cin", "registration_date", "corporate_body_name", "br_section", "br_insertion", "text", "street", "postal_code", "city"]
  $ORDER_VALUES = ["asc", "desc"]
  $SUBMISSION_VALUES = ["br_court_name", "kind_name", "cin", "registration_date", "corporate_body_name", "br_section", "br_insertion", "text", "street", "postal_code", "city"]

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

    #validate param values - use default if not present or incorrect
    page_num.negative? ? page_num = 0 : nil
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

    #prepare sql string
    date_sql = "WHERE registration_date >= '" + gte_date + "' AND registration_date <= '" + lte_date + "'"
    search_q.nil? ? search_sql = "" : search_sql = "AND POSITION('" + search_q + "' IN corporate_body_name)>0 OR POSITION('" + search_q + "' IN cin::text)>0 OR POSITION('" + search_q + "' IN city)>0"
    order_sql = "ORDER BY " + order_by + " " + order_type

    sql = "SELECT * FROM ov.or_podanie_issues 
    " + date_sql + search_sql + order_sql + " 
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
    #get params
    params.require(:submission)
    submission = params[:submission].clone
    submission.permit(:br_court_name, :kind_name, :cin, :registration_date, :corporate_body_name, :br_section, :br_insertion, :text, :street, :postal_code, :city)

    missing_params = []
    $SUBMISSION_VALUES.each do |param|
      submission[param].nil? || submission[param].to_s.strip.empty? ? missing_params << param : nil
    end
    missing_params.empty? ? nil : (return render_submission_error(missing_params))

    #validate submission values
    (submission[:cin].is_a? Integer) ? nil : missing_params << "cin"

    begin
      Date.iso8601(submission[:registration_date])
    rescue ArgumentError => e
      missing_params << "registration_date"
    end
    if (Date.today().to_s.to_i - submission[:registration_date].to_s.to_i) == 0
      nil
    else
      missing_params << "registration_date"
    end

    missing_params.empty? ? nil : (return render_submission_error(missing_params))

    #prepare missing values
    submission[:created_at] = submission[:updated_at] = Date.today().iso8601
    submission[:address_line] = submission[:street] + ", " + submission[:postal_code] + " " + submission[:city]

    #insert into ov.bulletin_issues
    time = "'" + Time.now().iso8601 + "'::timestamp"
    sql = "INSERT INTO ov.bulletin_issues (year, number, published_at, created_at, updated_at) 
    VALUES ( 2021 ,
      (SELECT number FROM ov.bulletin_issues ORDER BY number desc LIMIT 1) + 1,
    " + time + "," + time + "," + time + ") 
    RETURNING (id);"
    bulletin_id = ActiveRecord::Base.connection.execute(sql).getvalue(0, 0)

    #insert into ov.raw_issues
    sql = "INSERT INTO ov.raw_issues (bulletin_issue_id , file_name , content, created_at, updated_at)
    VALUES (" + bulletin_id.to_s + ",'-','-', " + time + "," + time + ") 
    RETURNING (id);"
    raw_id = ActiveRecord::Base.connection.execute(sql).getvalue(0, 0)

    #insert into ov.or_podanie_issues
    sql = "INSERT INTO ov.or_podanie_issues 
    (bulletin_issue_id, raw_issue_id, br_mark, br_court_name, br_court_code, kind_code, kind_name, cin, registration_date, corporate_body_name, br_section, br_insertion, text, street, 
      postal_code, city, updated_at, created_at, address_line)
    VALUES (" + bulletin_id.to_s + "," + raw_id.to_s + ",'-','" + submission[:br_court_name].to_s + "','-','-','" + submission[:kind_name].to_s + "'," + submission[:cin].to_s + "
    ,'" + submission[:registration_date].to_s + "','" + submission[:corporate_body_name].to_s + "','" + submission[:br_section].to_s + "','" + submission[:br_insertion].to_s + "'
    ,'" + submission[:text].to_s + "','" + submission[:street].to_s + "','" + submission[:postal_code].to_s + "','" + submission[:city].to_s + "','" + submission[:updated_at].to_s + "'
    ,'" + submission[:created_at].to_s + "','" + submission[:address_line].to_s + "') 
    RETURNING *;"
    response = ActiveRecord::Base.connection.execute(sql)

    #render
    render json: { response: format_response(response)[0] }, status: 201
  end

  #DELETE v1/ov/submissions/{id}
  def destroy
    #get params
    params.require("id")
    id = params[:id]

    #delete from ov.or_podanie_issues
    sql = "DELETE FROM ov.or_podanie_issues 
    WHERE id = '" + id + "' 
    RETURNING (raw_issue_id);"
    raw_id = ActiveRecord::Base.connection.execute(sql)

    raw_id.num_tuples.zero? ? (return render_error("Záznam neexistuje", 404)) : nil
    raw_id = raw_id.getvalue(0, 0)

    #delete from ov.raw_issues
    sql = "DELETE FROM ov.raw_issues 
    WHERE id = '" + raw_id.to_s + "' 
    RETURNING (bulletin_issue_id);"
    bulletin_id = ActiveRecord::Base.connection.execute(sql)

    bulletin_id.num_tuples.zero? ? (return render_error("Záznam neexistuje", 404)) : nil
    bulletin_id = bulletin_id.getvalue(0, 0)

    #delete from ov.bulletin_issues
    sql = "DELETE FROM ov.bulletin_issues 
    WHERE id = '" + bulletin_id.to_s + "';"
    res = ActiveRecord::Base.connection.execute(sql)

    #render status
    render status: 204
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

  def render_error(message, status_code)
    render json: { error: { message: message } }, status: status_code
  end

  def render_submission_error(arr)
    render_arr = []
    arr.each do |param|
      reasons = ["required"]
      param == "cin" ? reasons << "not_number" : nil
      param == "registration_date" ? reasons << "invalid_range" : nil
      render_arr << { field: param, reasons: reasons }
    end
    render json: { errors: render_arr }, status: 422
  end
end
