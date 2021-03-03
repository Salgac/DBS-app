class V1::Ov::SubmissionsController < ApplicationController

  #GET v1/ov/submissions
  def show
    render json: { test: "get" }
  end

  #POST v1/ov/submissions
  def create
    render json: { test: "post" }
  end

  #DELETE v1/ov/submissions
  def destroy
    render json: { test: "delete" }
  end
end
