class AnkensController < ApplicationController
  before_action :anken_find, only: [:show,:edit,:update,:destroy]
  before_action :comment_find, only: [:comment_edit,:comment_update,:comment_destroy]

  def index

    @anken = Anken.new

    if params[:anken].present?
      @anken.anken_name = params[:anken][:anken_name]
      @anken.anken_summary = params[:anken][:anken_summary]
      @anken.customer_id = params[:anken][:customer_id]
      @anken.tanto_id = params[:anken][:tanto_id]
      @anken.anken_status_cd = params[:anken][:anken_status_cd].map(&:to_i)
      @ankens = Anken.get_by_name(params[:anken][:anken_name]).get_by_summary(params[:anken][:anken_summary])
      .get_by_customer_id(params[:anken][:customer_id]).get_by_tanto_id(params[:anken][:tanto_id])
      .get_by_anken_status_cd(params[:anken][:anken_status_cd].map(&:to_i))
    else
        @ankens = Anken.includes([:customer,:tanto,:code_mst])
          .where(customers: {del_flg: 0},tantos: {del_flg: 0},code_msts: {category_cd: '0001',del_flg: 0})

          logger.debug @ankens.each.with_index(1){ |value, index| puts "#{index} : #{value}" }
    end

    #検索条件用オブジェクト
    @anken_search = Anken.new
    #検索条件用案件ステータス、クライアント、担当者
    getCustomers_for_options
    getTantos_for_options
    getCodemst_for_options('0001')

  end

  def new
    @anken = Anken.new

    #セレクトボックス用の値取得
    getCustomers_for_options
    getTantos_for_options
    getCodemst_for_options('0001')
  end

  def show
  end

  def edit

    #セレクトボックス用の値取得
    getCustomers_for_options
    getTantos_for_options
    getCodemst_for_options('0001')
  end

  def create
    @anken = Anken.new(anken_params)
    setLastUpdateUser

    #validationチェック
    if @anken.invalid?
      getCustomers_for_options
      getTantos_for_options
      getCodemst_for_options('0001')
      render :new, flash: {errors: @anken.errors.full_messages}
    else
      if @anken.save
        redirect_to ankens_path, success: '案件情報が登録されました。'
      else
        redirect_to ankens_new_path, danger: '案件情報の作成に失敗しました。'
      end
    end
  end

  def update
    #最終更新者をログインユーザーにセット
    setLastUpdateUser
    if @anken.update(anken_params)
      redirect_to ankens_path, success: '案件情報の更新が完了しました。'
    else
      redirect_to ankens_edit_path, danger: '案件の更新に失敗しました。'
    end
  end

  def destroy
    #最終更新者をログインユーザーにセット
    setLastUpdateUser
    if @anken.destroy
      redirect_to ankens_path, success: '案件情報の削除が完了しました。'
    else
      redirect_to ankens_path, danger: '案件の削除に失敗しました。'
    end
  end

  def comment
    logger.debug "testだよ。"
    @anken = Anken.find(params[:anken_id])
    @comment = Comment.new
    @title = "コメント登録"
  end

  def comment_show
    @anken = Anken.find(params[:id])
  end

  def comment_edit
    @anken = Anken.find(params[:anken_id])
    @comment = Comment.find(params[:id])
    @title = "コメント更新"
  end

  def comment_create
    @comment = Comment.new(comment_params)
    @comment.anken_id = params[:id]
    @comment.last_update = current_user.username
    if @comment.invalid?
      render :comment, flash: {errors: @comment.errors.full_messages}
    else
      if @comment.save
        redirect_to ankens_path, success: 'コメントが登録されました。'
      else
        redirect_to comments_path, danger: 'コメントの作成に失敗しました。'
      end
    end
  end

  def comment_update
    @comment.last_update = current_user.username
    if @comment.update(comment_params)
      redirect_to ankens_path, success: 'コメント更新が完了しました。'
    else
      redirect_to comments_path, danger: 'コメントの更新に失敗しました。'
    end
  end

  def comment_destroy
    if @comment.destroy
      redirect_to ankens_path, success: 'コメントの削除が完了しました。'
    else
      redirect_to ankens_path, danger: 'コメントの削除に失敗しました。'
    end
  end

  private
    #顧客情報を取得(有効なレコードのみ)
    def getCustomers_for_options
      @customers_for_options = Customer.where(del_flg: 0)
    end

    #担当者情報を取得(有効なレコードのみ)
    def getTantos_for_options
      @tantos_for_options = Tanto.where(del_flg: 0)
    end

    #コードマスタ情報と取得
    def getCodemst_for_options(categoryCd)
      @code_msts_for_options = CodeMst.where(category_cd: categoryCd).where(del_flg: 0)
    end

    def anken_find
      @anken = Anken.find(params[:id])
    end

    def comment_find
      @comment = Comment.find(params[:id])
    end

    def anken_params
      params.require(:anken).permit(:customer_id,:anken_name,:anken_summary,
      :anken_status_cd,:tanto_id,:anken_ball_cd,:remark)
    end

    def comment_params
      params.require(:comment).permit(:anken_id,:ymd,:anken_comment,:last_update)
    end

    def setLastUpdateUser
      @anken.last_update = current_user.username
    end
end
