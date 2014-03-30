class AttributeValuesController < ApplicationController
  before_action :set_attribute_value, only: [:show, :edit, :update, :destroy]

  # GET /attribute_values
  # GET /attribute_values.json
  def index
    @attribute_values = AttributeValue.all
  end

  # GET /attribute_values/1
  # GET /attribute_values/1.json
  def show
  end

  # GET /attribute_values/new
  def new
    @attribute_value = AttributeValue.new
  end

  # GET /attribute_values/1/edit
  def edit
  end

  # POST /attribute_values
  # POST /attribute_values.json
  def create
    @attribute_value = AttributeValue.new(attribute_value_params)

    respond_to do |format|
      if @attribute_value.save
        format.html { redirect_to @attribute_value, notice: 'Attribute value was successfully created.' }
        format.json { render action: 'show', status: :created, location: @attribute_value }
      else
        format.html { render action: 'new' }
        format.json { render json: @attribute_value.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /attribute_values/1
  # PATCH/PUT /attribute_values/1.json
  def update
    respond_to do |format|
      if @attribute_value.update(attribute_value_params)
        format.html { redirect_to @attribute_value, notice: 'Attribute value was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @attribute_value.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /attribute_values/1
  # DELETE /attribute_values/1.json
  def destroy
    @attribute_value.destroy
    respond_to do |format|
      format.html { redirect_to attribute_values_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_attribute_value
      @attribute_value = AttributeValue.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def attribute_value_params
      params.require(:attribute_value).permit(:article_id, :attribute_id, :value)
    end
end
