# Mriver-rails

rackup private_pub.ru -s thin -E production で非同期サーバーを立ち上げる


深いネスト(ネストしたリソースの中でさらに別のリソースをネスト)
routes.rb

resources :publishers do
  resources :magazines do
    resources :photos
  end
end

/publishers/1/magazines/2/photos/3 見にくい...ネスティングは一回まで

***「浅い」ネスト(コレクション (index/new/createのような、idを持たないアクション) だけを親のスコープの下で生成***

resources :posts do
  resources :comments, only: [:index, :new, :create]
end
resources :comments, only: [:show, :edit, :update, :destroy]


pathをコード化して整理
<routes.rb>
get '/patients/:id', to: 'patients#show', as: 'patient'

<controller>

@patient = Patient.find(3) //parient_id 3

<view>
<%= link_to 'Patient Record', patient_path(@patient) %>
<%= link_to 'Patient Record', '/patients/3' %> と同じ


***Rails deviseで使えるようになるヘルパーメソッド一覧***

before_action :authenticate_user!	コントローラーに設定して、ログイン済ユーザーのみにアクセスを許可する
user_signed_in?	ユーザーがサインイン済かどうかを判定する
current_user	サインインしているユーザーを取得する !!(モデル名が例えば　memberなら, current_member )
user_session	ユーザーのセッション情報にアクセスする


***モデルを生成して保存(create)***

使い方
モデル.create([属性])

例
user = User.create(name: "TestUser", profile: "profile")


***親モデル.子モデル.build(name: "Yuta Totz")***

user.books.build(title: "現場で使えるRuby on Rails第四版")
#=> #<Book id: nil, title: "現場で使えるRuby on Rails第四版", user_id: 3, ...>
# 未保存のBookモデルオブジェクト
# 保存するには user.books.last.save などを呼び出します。


###特定のIDのデータを取得(検索)したい###
# @article = Article.find(params[:id])

Modelから、paramsのidと同じidを持つデータを取得

@article.titleのように使う

###特定のカラムの値から1つのデータを取得(検索)したい###
# @user = User.find_by(email: params[:email])

@user.emailのように使う

###フォームを生成(form_for/form_tag)###

使い方
form_for(モデルオブジェクト [, オプション]) do |f|
end

オプション	説明
:url	フォームの送信先
:namespace	名前空間の設定
:html	タグの属性


# hidden_field

f.hidden_field :shampoo_id, :value => shampoo.id (第一引数にオブジェクト名、第二引数部分にvalue)

# hidden_field_tag
hidden_field_tag :email, @user.email
<!-- params[:email]に保存 -->


###フォーム抜き出し###

/listings/:listing_id/reservations
@listing = Listing.find(params[:id])

<%= form_for [@listing, @listing.reservations.new] do |f| %>    
<!--listingは@listing.reservations.newにネストされているので、引数となる配列は[親, 子] -->
                                           
                                <!-- これは、予約をするときに、一緒におくる、データです。-->
                                <%= f.hidden_field :listing_id, value: @listing.id %>
                                <%= f.hidden_field :price_pernight, value: @listing.price_pernight %>
                                <%= f.hidden_field :total_price, id:'reservation_total_price' %>
                                :listing_idは、reservationsの情報の一つ


                                <div class="row row-space-2">
                                    <div class="col-md-6">
                                        <label>Check In</label>
                                          <%= f.text_field :start_date, :class => 'form-control', placeholder: '開始' %>
                                    </div>

                                    <div class="col-md-6">
                                        <label>Check Out</label>
                                        <%= f.text_field :end_date, :class => 'form-control', placeholder: '終了' %>
                                    </div>
                                </div>            

                                <div class="actions text-center">
                                    <%= f.submit "この日程で予約する", class: "btn btn-danger btn-wide" %>
                                </div>
                            <% end %>

投稿ボタンが押されたら(submit)、reservations#createへ繋げたい。 POST /listings/:listing_id/reservations(.:format)

reservationsコントローラのcreateアクションでresservationクラスのインスタンスをcreateして、そこに保存。(その際privateで)

※createメソッドは、newとsaveを同時にできる
reservation画面に即座にリダイレクトさせる。

	class ReservationsController < ApplicationController
		before_action :authenticate_user!

	  def create 
	  	@reservation = current_user.reservations.create(reservation_params)

	  	redirect_to @reservation.listing, notice:"予約が完了しました。"
	  end

	  private
	    def reservation_params
	  	  params.require(:reservation).permit(:start_date, :end_date, :price_pernight, :total_price, :listing_id)
	    end
	end