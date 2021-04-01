class V1::CompaniesController < ApplicationController

  #GET v1/ov/submissions
  def show
    render json: { hello: "world" }
  end
end
