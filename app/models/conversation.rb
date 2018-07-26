class Conversation < ActiveRecord::Base
  # Conversation ModelからはUser Modelを(Conversation.userメソッドではなく)Conversation.sender or Conversation.recipient メソッドで参照
  # conversationsテーブルの外部キーはsender_id or recipient_id フィールド
  # class_nameは対象となるモデルを指定して，foreign_keyで，どのカラムの値が一致するレコードを取得するのかを指定します．
  belongs_to :sender, :foreign_key => :sender_id, class_name: 'User'
  belongs_to :recipient, :foreign_key => :recipient_id, class_name: 'User'


  has_many :messages, dependent: :destroy
  
  # conversationsデーブルに、同一のrecipient_idに対するsender_idは一意であるという制約を持たせている。
  # 特定の二人のConversationはひとつ
  validates_uniqueness_of :sender_id, :scope => :recipient_id

  #scopeは長い条件文を省略するために使用
  # よく使うクエリはモデルにscopeを使って切り出すと良い
  # userを使ってクエリの条件を書ける 単なるuserは引数
  scope :involving, -> (user) do
    where("conversations.sender_id =? OR conversations.recipient_id =?",user.id,user.id)
  end

  scope :between, -> (sender_id,recipient_id) do
    where("(conversations.sender_id = ? AND conversations.recipient_id = ?) OR (conversations.sender_id = ? AND conversations.recipient_id = ?)", sender_id, recipient_id, recipient_id, sender_id)
  end
end

# validates_presence_of :favorite_team, :scope => :login_name
# 同じ login_name を持つ人限定で、重複した favorite_team を複数 insert したり update したり出来なくなります
# login_name = 1, favorite_team = 広島
# login_name = 2, favorite_team = 巨人

# というデータがテーブルの中にあったとして、新たに次のデータは挿入できます。

# login_name = 1, favorite_team = 巨人
# login_name = 2, favorite_team = 広島

# でも、次のデータは挿入できません

# login_name = 1, favorite_team = 広島
# login_name = 2, favorite_team = 巨人

# というわけでした