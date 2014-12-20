class Admin::NewsController < Admin::BaseController
  before_filter :find_blog, only: [:show, :edit, :update, :destroy]

  def index
    @blogs = Blog.order("created_at asc")
  end

  def new
    @blog = Blog.new(published_at: Time.now, user_id: current_user.id)
    @users = User.all
  end

  def image_edit
    @listicle = Listicle.find(params[:id])
    @blog = @listicle.blog
  end

  def show
    redirect_to edit_admin_news_url
  end

  def edit
    @users = User.all
  end

  def update
    if params[:cropping_bait_block]
      bb = BaitBlock.find(params[:bait_block_id])
      bb.update_attribute :crop_top_offset, params[:crop_top_offset]
      BaitBlockImageSizeWorker.perform_async(bb.id)
      flash[:notice] = "Image crop updated"
      redirect_to image_edit_admin_news_url(id: bb.id)
    else
      body = "blog"
      title = params[:blog][:title]
      body = params[:blog][:body]
      if @blog.update_attributes(params[:blog])
        @blog.reload
        if @blog.listicles.present?
          @blog.listicles.pluck(:id).each { |id| ListicleImageSizeWorker.perform_in(1.minutes, id) }
        end
        flash[:notice] = "Blog saved!"
        redirect_to edit_admin_news_url(@blog)
      else
        @users = User.blog_admin
        render action: :edit
      end
    end
  end

  def create
    @blog = Blog.create({
      title: params[:blog][:title],
      user_id: current_user.id,
      body: "No content yet, write some now!",
      published_at: Time.now,
      is_listicle: params[:blog][:is_listicle]
    })
    if @blog.save
      flash[:notice] = "Blog created!"
      redirect_to edit_admin_news_url(@blog)
    else
      flash[:error] = "Blog error! #{@blog.errors.full_messages.to_sentence}"
      redirect_to new_admin_news_index_url
    end
  end

  def destroy
    @blog.destroy
    redirect_to admin_news_index_url
  end

  protected

  def find_blog
    @blog = Blog.find_by_title_slug(params[:id])
  end
end
