#This class will consume showoff API calls by using ShowoffApiConnectorService class.
module ShowoffApiService
    include ShowoffApiConnectorService
    
    private

    #This method will list current user's all widgets and other user's visible widgets only. 
    def visible_widgets
        begin
            user_id, user_info = params[:id], params[:user_info]
            if user_info.eql?("true") 
                my_widgets_url = MY_USER_WIDGETS + "client_id=#{client_id}&client_secret=#{client_secret}" 
                response = showoff_api_call(my_widgets_url, "get", authorization_bearer(current_user.showoff_access_token))
            else
                user_widgets_url = USER_WIDGETS + "#{user_id}/widgets/?client_id=#{client_id}&client_secret=#{client_secret}"
                response = showoff_api_call(user_widgets_url, "get", {})
            end
            if response["data"]["widgets"].present?
                @user = response["data"]["widgets"].first["user"] 
                @widgets = response["data"]["widgets"] if response["data"].present?
            else
                @user = nil
                @widgets = []
            end
            response = 200
        rescue => exception
            @user = nil
            @widgets = []
            flash[:error] = "Something went wrong in user show! #{exception}"
        end
    end

    #This method will list all visible widgets. 
    def all_visible_widgets
        begin
            user_id = params[:id]
            api_link = VISIBLE_WIDGETS_URL + client_id + "&client_secret=" + client_secret
            response = showoff_api_call(api_link,"get")
            @widgets = response["data"]["widgets"]
            code = response["code"]
            flash[:error] = response["message"] if code != 0
        rescue => exception
            flash[:error] = "Something went wrong in widgets index! #{exception}"
        end
    end

    #Displays logged_in users widgets
    def my_widgets
        begin
            api_link = USER_WIDGETS + current_user.showoff_user_id.to_s + "/widgets?client_id=" + client_id + "&client_secret=" + client_secret #Using User ID API
            response = showoff_api_call(api_link,"get", authorization_bearer(current_user.showoff_access_token))  
            @widgets = response["data"]["widgets"]
            code = response["code"]
            flash[:error] = response["message"] if code != 0
        rescue => exception
            flash[:error] = "Something went wrong in widgets my_widgets! #{exception}"
        end
    end

    def create_widget
        begin
            body = {
                "name": params[:widget]["name"],
                "description": params[:widget]["name"],
                "kind": params[:widget]["kind"]
                }
            response = showoff_api_call(WIDGETS_URL, "post", authorization_bearer(current_user.showoff_access_token), body)
            @widget = response["data"]["widget"]
            widget = current_user.widgets.create(body) #entering data in table as well
            widget.update_attributes(showoff_widget_id: @widget["id"])
            code = response["code"].to_i
            if code == 0
                redirect_to my_widget_path, notice: 'Widget was successfully created.'
            else
                redirect_to new_widget_path, flash: { error: response["message"] }
            end
        rescue => exception
            flash[:error] = "Something went wrong in widgets create! #{exception}"
        end
    end

    def update_widget
        begin
            widget = Widget.find_by_id(params[:id])
            #Updating the widget details
            if widget.present?
                authorization = "Bearer " + current_user.showoff_access_token.to_s
                api_link = WIDGET_URL + widget.showoff_widget_id.to_s
                body =  {
                            "widget": {
                                        "name": params[:widget]["name"],
                                        "description": params[:widget]["description"],
                                        "kind": params[:widget]["kind"],
                                    }
                        }
                @widget = showoff_api_call(api_link, "put", authorization, body)
                code = @widget["code"]
                if code == 0 && widget.update(widget_params)
                    redirect_to my_widget_path, notice: 'Widget was successfully updated.'
                else
                    redirect_to my_widget_path, flash: { error: "Something went wrong in updating. #{@widget[:message]}" }
                end
            end
        rescue => exception
            flash[:error] = "Something went wrong in widgets udpate! #{exception}"
        end
    end
    
    def destroy_widget
        begin
            #Destroy/Delete the widget
            api_link = WIDGET_URL + params[:id]
            @widget = showoff_api_call(api_link, "delete", authorization_bearer(current_user.showoff_access_token)) #deleteing widget from showoff database
            code = @widget["code"]
            redirect_path = my_widget_path
            if(code == 0)
                redirect_to redirect_path, notice: 'Widget was successfully destroyed.'
            else
                redirect_to redirect_path, flash: { error: "Something went wrong in destroying widget. #{@widget["message"]}" }
            end
        rescue => exception
            flash[:error] = "Something went wrong in widgets destruction! #{exception}"
        end
    end

    #Searching for a particular word in a widget
    def search_widgets
        begin
            if current_user.present?
                api_link = USER_WIDGETS + current_user.showoff_user_id.to_s + "/widgets?client_id=" + client_id + "&client_secret=" + client_secret + "&term=" + params[:search].to_s #using User ID API
            else
                api_link = VISIBLE_WIDGETS_URL + client_id + "&client_secret=" + client_secret + "&term=" + params[:search].to_s
            end
            response = showoff_api_call(api_link,"get")
            @widgets = response["data"]["widgets"]
            code = response["code"]
            flash[:error] = response["message"] if code != 0
        rescue => exception
            flash[:error] = "Something went wrong in widgets index! #{exception}"
        end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def widget_params
        params.require(:widget).permit(:name, :description, :kind)
    end
end