class PagesController < ApplicationController
  def index #views/index.html.erbを表示させるというアクション
    @users = User.all
  end

  def search
    # テキストフィールドのパラメータを送信している
    if params[:search].present?

      session[:address] = params[:search]

      if params["lat"].present? & params["lng"].present?
        @latitude = params["lat"]
        @longitude = params["lng"]

        geolocation = [@latitude,@longitude]

      else
        # Geocoder.coordinates("パリ")みたいにして, 場所の2次元座標を計測する
        geolocation = Geocoder.coordinates(params[:search])
        # geolocation => [122.1311, 134.3231] みたいに配列で返される!!
        @latitude = geolocation[0]
        @longitude = geolocation[1]
      end

      # gem geocoderのメソッド 1マイル(1.6km)以内のデータを取得
      @listings = Listing.where(active: true).near(geolocation, 1, order: 'distance')

    # 検索欄が空欄の場合(パラメータを送信していない)
    else
      # [公開する]に設定したリスト全てを抽出
      @listings = Listing.where(active: true).all
      @latitude = @listings.to_a[0].latitude
      @longitude = @listings.to_a[0].longitude
      # to_a について (1..7).to_a #=> [1, 2, 3, 4, 5, 6, 7] {'a'=>1,'b'=>2,'c'=>3 }.to_a #=> [["a", 1], ["b", 2], ["c", 3]]
    end

    # Ransack q のチェックボックス一覧
    # フィルタリングしたparamsが存在するとき
    if params[:q].present?
      # viewでフィルタリングしたparams[:q]の中に[:price_pernight_gteq]が存在するとき
      # sessionに入れる
      if params[:q][:price_pernight_gteq].present?
        session[:price_pernight_gteq] = params[:q][:price_pernight_gteq]
      else
        # sessionを破棄する
        session[:price_pernight_gteq] = nil
      end

      # viewでフィルタリングしたparams[:q]の中に[:price_pernight_lteq]が存在するとき
      # sessionに入れる
      if params[:q][:price_pernight_lteq].present?
        session[:price_pernight_lteq] = params[:q][:price_pernight_lteq]
      else
        # sessionを破棄する
        session[:price_pernight_lteq] = nil
      end

      # viewでフィルタリングしたparams[:q]の中に[:home_type_eq_any]が存在するとき
      # 一軒家,マンション,アパートアパートに該当するものをそれぞれtrue-falseで判定
      if params[:q][:home_type_eq_any].present?
        session[:home_type_eq_any] = params[:q][:home_type_eq_any]
        session[:House] = session[:home_type_eq_any].include?("一軒家")
        session[:Mansion] = session[:home_type_eq_any].include?("マンション")
        session[:Apartment] = session[:home_type_eq_any].include?("アパート")
      else
        session[:home_type_eq_any] = ""
        session[:House] = false
        session[:Mansion] = false
        session[:Apartment] = false
      end

      if params[:q][:pet_type_eq].present?
        session[:pet_type_eq] = params[:q][:pet_type_eq]
      else
        session[:pet_type_eq] = nil
      end

      if params[:q][:breeding_years_gteq].present?
        session[:breeding_years_gteq] = params[:q][:breeding_years_gteq]
      else
        session[:breeding_years_gteq] = nil
      end

    end

    # Q条件をまとめたものをセッションQに入れる [gteq 以上 lteq 以下 ]
    session[:q] = {"price_pernight_gteq"=>session[:price_pernight_gteq], "price_pernight_lteq"=>session[:price_pernight_lteq],  "home_type_eq_any"=>session[:home_type_eq_any], "pet_type_eq"=>session[:pet_type_eq], "breeding_years_gteq"=>session[:breeding_years_gteq]}

    # ransack検索
    @search = @listings.ransack(session[:q])
    @result = @search.result(distinct: true)

    #リスティングデータを配列にしてまとめる 
    @arrlistings = @result.to_a

    # start_date end_dateの間に予約がないことを確認.あれば削除
    if ( !params[:start_date].blank? && !params[:end_date].blank? )

      # session 一時的に保存する機能 ページが変わってもsessionは持続する
      session[:start_date] = params[:start_date]
      session[:end_date] = params[:end_date]

      start_date = Date.parse(session[:start_date])
      end_date = Date.parse(session[:end_date])

      # unavailables = []

      @listings.each do |listing|

        # @listingのうち、すでに予約されているリストを@arrlistingsから削除 最後には未予約の
        # 開始日が期間に重なる 終了日が重なる 開始日も終了日も重なる
        unavailable = listing.reservations.where(
            "(? <= start_date AND start_date <= ?)
              OR (? <= end_date AND end_date <= ?) 
              OR (start_date < ? AND ? < end_date)",
            start_date, end_date,
            start_date, end_date,
            start_date, end_date
        ).limit(1)

    #     if unavailable.length > 0
    #       # unavailables.push(listing)と同義
    #       unavailables << listing
    #     end
    #   end

    #     # delete unavailable room from @listings
    #     # 例 arrlistings => [list1,list2,list3] unavailables => [list1,list2] の時 引き算は [list3]
    #   @arrlistings = @arrlistings - unavailables
    # end

        # @listingsからunavailableを削除する
        if unavailable.length > 0
          # @listings.delete(listing)にすると、リストそのものが消える 細分化した配列からオブジェクトを消す
          @arrlistings.delete(listing)
        end
      end
    end
  end

  def ajaxsearch
    # まずajaxで送られてきた緯度経度をセッションに入れる
    if !params[:geolocation].blank?
      geolocation = params[:geolocation]
    end

    # まずajaxで送られてきた緯度経度をセッションに入れる
    if !params[:location].blank?
      session[:address] = params[:location]
    end

    # autocompleteで取得した地点の1マイル(1.6km)以内のリストを取得する
    @listings = Listing.where(active: true).near(geolocation, 1, order: 'distance')
    #リスティングデータを配列にしてまとめる 
    @arrlistings = @listings.to_a

    # start_date end_dateの間に予約がないことを確認.あれば削除
    if ( !session[:start_date].blank? && !session[:end_date].blank? )

      start_date = Date.parse(session[:start_date])
      end_date = Date.parse(session[:end_date])

      @listings.each do |listing|
        # @listingのうち、すでに予約されているリストを@arrlistingsから削除 最後には未予約の
        # 開始日が期間に重なる 終了日が重なる 開始日も終了日も重なる 
        unavailable = listing.reservations.where(
          "(? <= start_date AND start_date <= ?) 
          OR (? <= end_date AND end_date <= ?) 
          OR (start_date < ? AND ? < end_date)",
            start_date, end_date,
            start_date, end_date,
            start_date, end_date
        ).limit(1)

        # if unavailable.length > 0
        #   # unavailables.push(listing)と同義
        #   unavailables << listing
        # end

        if unavailable.length > 0
          # @listings.delete(listing)にすると、リストそのものが消える 細分化した配列からオブジェクトを消す
          @arrlistings.delete(listing)
        end
      end
      # @arrlistings = @arrlistings - unavailables
    end

    # 出力形式をjsにする
    respond_to :js
  end

end


# https://teratail.com/questions/88025
