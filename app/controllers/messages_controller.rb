class MessagesController < ApplicationController

  before_action :authenticate_user!
  before_action :set_conversation

  # redirect_to this action from conversation controller create action
  def index
    # pramsのconversationの送り手か受取手がcurrent_userなら相手は受取手か送り手(自分と逆)
    # このconversation_idに該当するmessagesを降順で取得
    if current_user == @conversation.sender || current_user == @conversation.recipient
      @other = current_user == @conversation.sender ? @conversation.recipient : @conversation.sender
      @messages = @conversation.messages.order("created_at DESC")
    else
      # この会話にcurrent_userは全く関係ないのでindexアクションを実行させない(メッセージのやりとりページを見せない)
      # 私のuser本来のメッセージ管理ページに飛ばす
      redirect_to conversations_path, alert: "他人のメッセージにアクセスできません"
    end

  end

  def create
    @message = @conversation.messages.new(message_params)
    @messages = @conversation.messages.order("created_at DESC")

    if @message.save
      #create.js.erb　が実行される
      # respond_toメソッドは、リクエストで指定されたフォーマット（HTML,JSON,XML）に合わせて結果を返すメソッド
      # createアクションをcreate.js形式に変換
      respond_to do |format|
        format.js
      end
    end
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end

  def message_params
    params.require(:message).permit(:body, :user_id)
  end
end