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
    order_type = params[:order_type]

    #validate param values - use default if not present or incorrect
    page_num.zero? ? page_num = 1 : nil
    per_page.zero? ? per_page = 10 : nil

    order_by.in?($QUERY_VALUES) ? nil : order_by = "registration_date"
    order_type.in?($ORDER_VALUES) ? nil : order_type = "desc"

    begin
      Date.iso8601(gte_date)
      Date.iso8601(lte_date)
    rescue ArgumentError => e
      gte_date.nil? ? gte_date = Date.new(1900, 1, 1).to_s : nil
      lte_date.nil? ? lte_date = Date.today().to_s : nil
    end

    #get values and render
    query = OrPodanieIssue.select($QUERY_VALUES)
      .where(registration_date: gte_date..lte_date)
      .order(order_by => order_type)
      .page(page_num).per(per_page)
    search_q.nil? ? nil : query = query.where("corporate_body_name LIKE :s OR cin::text LIKE :s OR city LIKE :s", s: "%#{search_q}%")

    render json: { items: query, metadata: { page: page_num, per_page: per_page, pages: query.total_pages, total: query.total_count } },
           status: 200
  end

  #POST v2/ov/submissions
  def create
    submission = params[:submission].clone
    submission.permit($SUBMISSION_VALUES)

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
    time = Time.now().iso8601

    #insert into ov.bulletin_issues
    bulletin = BulletinIssue.new(
      year: 2021,
      number: BulletinIssue.last(1).pluck(:number)[0] + 1,
      published_at: time,
      created_at: time,
      updated_at: time,
    )
    bulletin.save

    #insert into ov.raw_issues
    raw = RawIssue.new(
      bulletin_issue_id: bulletin.id,
      file_name: " - ",
      content: " - ",
      created_at: time,
      updated_at: time,
    )
    raw.save

    #insert into ov.or_podanie_issues
    issue = OrPodanieIssue.new(
      bulletin_issue_id: bulletin.id,
      raw_issue_id: raw.id,
      br_mark: " - ",
      br_court_name: submission[:br_court_name].to_s,
      br_court_code: " - ",
      kind_code: " - ",
      kind_name: submission[:kind_name].to_s,
      cin: submission[:cin],
      registration_date: submission[:registration_date].to_s,
      corporate_body_name: submission[:corporate_body_name].to_s,
      br_section: submission[:br_section].to_s,
      br_insertion: submission[:br_insertion].to_s,
      text: submission[:text].to_s,
      street: submission[:street].to_s,
      postal_code: submission[:postal_code].to_s,
      city: submission[:city].to_s,
      updated_at: submission[:updated_at].to_s,
      created_at: submission[:created_at].to_s,
      address_line: submission[:address_line].to_s,
    )
    issue.save

    render json: { response: issue.slice($QUERY_VALUES) }, status: 201
  end

  #DELETE v2/ov/submissions/:id
  def destroy
    params.permit(:id)

    #delete from ov.or_podanie_issues
    issue = OrPodanieIssue.find_by_id(params[:id])
    issue.nil? ? (return render_error("Záznam neexistuje", 404)) : nil
    raw_id = issue.raw_issue_id
    issue.destroy

    #delete from ov.raw_issues
    raw = RawIssue.find_by_id(raw_id)
    raw.nil? ? (return render_error("Záznam neexistuje", 404)) : nil
    bulletin_id = raw.bulletin_issue_id
    raw.destroy

    #delete from ov.bulletin_issues
    bulletin = BulletinIssue.find_by_id(bulletin_id)
    bulletin.nil? ? (return render_error("Záznam neexistuje", 404)) : nil
    bulletin.destroy

    #render status
    render status: 204
  end

  #GET v2/ov/submissions/:id
  def show
    params.permit(:id)

    query = OrPodanieIssue.select($QUERY_VALUES).find_by_id(params[:id])

    query.nil? ? render_error("Invalid range", 422) : (render json: { response: query }, status: 200)
  end

  #PUT v2/ov/submissions/:id
  def update
  end

  #############
  ## HELPERS ##
  #############

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
