class KnowledgesController < ApplicationController
  before_action :set_knowledge, only: %i[ show update destroy ]

  # GET /knowledges
  def index
    @knowledges = Knowledge.all

    render json: @knowledges
  end

  # GET /knowledges/1
  def show
    render json: @knowledge
  end

  # POST /knowledges
  def create
    @knowledge = Knowledge.new(knowledge_params)

    if @knowledge.save
      render json: @knowledge, status: :created, location: @knowledge
    else
      render json: @knowledge.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /knowledges/1
  def update
    if @knowledge.update(knowledge_params)
      render json: @knowledge
    else
      render json: @knowledge.errors, status: :unprocessable_entity
    end
  end

  # DELETE /knowledges/1
  def destroy
    @knowledge.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_knowledge
      @knowledge = Knowledge.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def knowledge_params
      params.require(:knowledge).permit(:category, :keyword, :content)
    end
end
