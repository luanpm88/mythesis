class InfoboxTemplatesController < ApplicationController
  before_action :set_infobox_template, only: [:show, :edit, :update, :destroy]

  # GET /infobox_templates
  # GET /infobox_templates.json
  def index
    @infobox_templates = InfoboxTemplate.all
  end

  # GET /infobox_templates/1
  # GET /infobox_templates/1.json
  def show
  end

  # GET /infobox_templates/new
  def new
    @infobox_template = InfoboxTemplate.new
  end

  # GET /infobox_templates/1/edit
  def edit
  end

  # POST /infobox_templates
  # POST /infobox_templates.json
  def create
    @infobox_template = InfoboxTemplate.new(infobox_template_params)

    respond_to do |format|
      if @infobox_template.save
        format.html { redirect_to @infobox_template, notice: 'Infobox template was successfully created.' }
        format.json { render action: 'show', status: :created, location: @infobox_template }
      else
        format.html { render action: 'new' }
        format.json { render json: @infobox_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /infobox_templates/1
  # PATCH/PUT /infobox_templates/1.json
  def update
    respond_to do |format|
      if @infobox_template.update(infobox_template_params)
        format.html { redirect_to @infobox_template, notice: 'Infobox template was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @infobox_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /infobox_templates/1
  # DELETE /infobox_templates/1.json
  def destroy
    @infobox_template.destroy
    respond_to do |format|
      format.html { redirect_to infobox_templates_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_infobox_template
      @infobox_template = InfoboxTemplate.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def infobox_template_params
      params.require(:infobox_template).permit(:name)
    end
end
