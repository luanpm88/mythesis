class TestArticleAttributeSentencesController < ApplicationController
  before_action :set_test_article_attribute_sentence, only: [:show, :edit, :update, :destroy]

  # GET /test_article_attribute_sentences
  # GET /test_article_attribute_sentences.json
  def index
    @test_article_attribute_sentences = TestArticleAttributeSentence.all
  end

  # GET /test_article_attribute_sentences/1
  # GET /test_article_attribute_sentences/1.json
  def show
  end

  # GET /test_article_attribute_sentences/new
  def new
    @test_article_attribute_sentence = TestArticleAttributeSentence.new
  end

  # GET /test_article_attribute_sentences/1/edit
  def edit
  end

  # POST /test_article_attribute_sentences
  # POST /test_article_attribute_sentences.json
  def create
    @test_article_attribute_sentence = TestArticleAttributeSentence.new(test_article_attribute_sentence_params)

    respond_to do |format|
      if @test_article_attribute_sentence.save
        format.html { redirect_to @test_article_attribute_sentence, notice: 'Test article attribute sentence was successfully created.' }
        format.json { render action: 'show', status: :created, location: @test_article_attribute_sentence }
      else
        format.html { render action: 'new' }
        format.json { render json: @test_article_attribute_sentence.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /test_article_attribute_sentences/1
  # PATCH/PUT /test_article_attribute_sentences/1.json
  def update
    respond_to do |format|
      if @test_article_attribute_sentence.update(test_article_attribute_sentence_params)
        format.html { redirect_to @test_article_attribute_sentence, notice: 'Test article attribute sentence was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @test_article_attribute_sentence.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /test_article_attribute_sentences/1
  # DELETE /test_article_attribute_sentences/1.json
  def destroy
    @test_article_attribute_sentence.destroy
    respond_to do |format|
      format.html { redirect_to test_article_attribute_sentences_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_test_article_attribute_sentence
      @test_article_attribute_sentence = TestArticleAttributeSentence.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def test_article_attribute_sentence_params
      params.require(:test_article_attribute_sentence).permit(:article_id, :attribute_id, :sentence)
    end
end
