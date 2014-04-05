class ArticlesController < ApplicationController
  before_action :set_article, only: [:show, :edit, :update, :destroy]

  # GET /articles
  # GET /articles.json
  def index
    @articles = Article.all
  end

  # GET /articles/1
  # GET /articles/1.json
  def show
  end

  # GET /articles/new
  def new
    @article = Article.new
  end

  # GET /articles/1/edit
  def edit
  end

  # POST /articles
  # POST /articles.json
  def create
    @article = Article.new(article_params)

    respond_to do |format|
      if @article.save
        format.html { redirect_to @article, notice: 'Article was successfully created.' }
        format.json { render action: 'show', status: :created, location: @article }
      else
        format.html { render action: 'new' }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /articles/1
  # PATCH/PUT /articles/1.json
  def update
    respond_to do |format|
      if @article.update(article_params)
        format.html { redirect_to @article, notice: 'Article was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /articles/1
  # DELETE /articles/1.json
  def destroy
    @article.destroy
    respond_to do |format|
      format.html { redirect_to articles_url }
      format.json { head :no_content }
    end
  end
  
  def import
    Article.import
    
    render nothing: true
  end
  
  def create_raw_attribute_value
    Article.create_raw_attribute_value
    
    render nothing: true
  end
  
  def create_senteces_file
    Article.create_senteces_file
    
    render nothing: true
  end
  
  def write_article_to_files
    Article.write_article_to_files
    
    render nothing: true
  end
  
  def find_sentences_with_value
    Article.find_sentences_with_value
    
    render nothing: true
  end
  
  def create_doccat_training_file
    Article.create_doccat_training_file
    
    render nothing: true
  end
  
  def train_doccat
    Article.train_doccat
    
    render nothing: true
  end
  
  def create_vector_space_for_attribute
    Article.create_vector_space_for_attribute
    
    render nothing: true
  end
  
  def create_train_for_filter_by_cluster
    Article.create_train_for_filter_by_cluster
    
    render nothing: true
  end
  
  def create_training_data_for_CRF
    Article.create_training_data_for_CRF
    
    render nothing: true
  end
  
  def training_CRF
    Article.training_CRF
    
    render nothing: true
  end
  
  def test_CRF
    Article.test_CRF
    
    render nothing: true
  end
  
  def doccat_test_files
    Article.doccat_test_files
    
    render nothing: true
  end
  
  def create_test_files_crf
    Article.create_test_files_crf
    
    render nothing: true
  end
  
  def filter
    Article.filter(41)
    
    render nothing: true
  end
  
  def get_result
    Article.get_result
    
    render nothing: true
  end
  
  def run_all
    Article.run_all
    
    render nothing: true
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_article
      @article = Article.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def article_params
      params.require(:article).permit(:title, :content)
    end
end
