require 'uri'
require 'net/http'
require 'net/https'
require 'json'
require 'cli/ui'            # 请输入 xxx的功能
require "spreadsheet/excel" # excel的导出使用

# 钉钉机器人
class DingDing
    # 发送 markdown 消息
    def DingDing.send_markdown(title, markdown) 
        token = ''
        params = %Q+{
            'msgtype': 'markdown',
            'markdown': {
            'title': '#{title}',
            'text': '#{markdown}'
            }
        }+

        `curl --silent \
            -H \"Content-Type: application/json\" \
            -d \"#{params}\" \
            https://oapi.dingtalk.com/robot/send?access_token=#{token}`
    end
end

#网络请求类
class Network    
    def Network.request (url, &block)
        uri = URI.parse(url)
        https = Net::HTTP.new(uri.host,uri.port)
        https.use_ssl = true
        req = Net::HTTP::Get.new(uri.path, initheader = {'Content-Type' =>'application/json'})
        req['Authorization'] = 'token '
        res = https.request(req)
        if res.code == "200"
            data = JSON.parse(res.body)
            # 回调data数据
            yield data
        else 
            puts "url = #{url}, 请求失败 : Response code = #{res.code}, message = #{res.message}"
        end
    end

    def Network.get (url, &block) 
        uri = URI.parse(url)
        https = Net::HTTP.new(uri.host,uri.port)
        https.use_ssl = true
        req = Net::HTTP::Get.new(uri.path, initheader = {'Content-Type' =>'application/json'})
        res = https.request(req)
        if res.code == "200"
            data = JSON.parse(res.body)
            # 回调data数据
            yield data
        else 
            yield false
            puts "url = #{url}, 请求失败 : Response code = #{res.code}, message = #{res.message}"
        end
    end
end

# Excel 参考 : https://github.com/zdavatz/spreadsheet/blob/master/GUIDE.md
#设置表格的编码为utf-8
Spreadsheet.client_encoding = "utf-8"
#创建表格对象
book = Spreadsheet::Workbook.new
#创建工作表
sheet1 = book.create_worksheet :name => "summerxx专属表"
#格式
sheet1.row(0).height = 28
for i in 0..19
    sheet1.column(i).width = 20
end

#在表格第一行设置分类
sheet1.row(0)[0] = "full_name"
sheet1.row(0)[1] = "html_url"
sheet1.row(0)[2] = "description"
sheet1.row(0)[3] = "forks_count"
sheet1.row(0)[4] = "created_at"
sheet1.row(0)[5] = "updated_at"
sheet1.row(0)[6] = "pushed_at"
sheet1.row(0)[7] = "stargazers_count"
sheet1.row(0)[8] = "subscribers_count"
sheet1.row(0)[9] = "open_issues_count"
sheet1.row(0)[10] = "fork"
sheet1.row(0)[11] = "has_wiki"
sheet1.row(0)[12] = "has_pages"
sheet1.row(0)[13] = "archived"
sheet1.row(0)[14] = "disabled"
sheet1.row(0)[15] = "license"
sheet1.row(0)[16] = "language"
sheet1.row(0)[17] = "openranksum"
sheet1.row(0)[18] = "activitysum"

# 参照: https://github.com/Shopify/cli-ui
username = CLI::UI::Prompt.ask('请输入您要查询的用户名例如 ruby:')
page = CLI::UI::Prompt.ask('由于每页最多查询 100 条数据, 请输入您要查询页码:')
puts "您确定要查询的是这个用户吗: #{username}, 并且页码为: #{page}"
sure = CLI::UI::Prompt.ask('确定请选择 Yes, 否定请选择 No') do |handler|
    handler.option('yes')  { |selection| selection }
    handler.option('no')     { |selection| selection }
end

if sure == "no"
    return
end

# url
url = "https://api.github.com/users/#{username}/repos?page=#{page}&per_page=100"

Network.request(url) { | data |

    if data 
        #创建一个 names 数组
        names = Array.new
        #遍历得到每个 repo 的对象
        for i in 0..data.count
            repo = data[i]
            # 判断 repo 非空
            if repo
            # puts "full_name = #{repo["full_name"]}, i = #{i}"
            # 添加数据进入数组
            names << repo["full_name"]
            end
        end

        for i in 0..names.count - 1
            name = names[i]
            url = "https://api.github.com/repos/#{name}"
            # puts url
            Network.request(url) { | data |
                # 判断 repo 非空
                if data

                    openrankurl = "https://oss.x-lab.info/open_digger/github/#{data["full_name"]}/openrank.json"
                    activityurl = "https://oss.x-lab.info/open_digger/github/#{data["full_name"]}/activity.json"

                    Network.get(openrankurl) { | v |
                        openrank_sum = 0.0
                        activity_sum = 0.0
                        if v 
                            values = Hash.new
                            values = v
                            values.each_value { | value |
                                openrank_sum = openrank_sum + value
                            }
                        end

                        Network.get(activityurl) { | v |
                            sum = 0.0
                            if v 
                                values = Hash.new
                                values = v
                                values.each_value { | value |
                                    activity_sum = activity_sum + value
                                }
                            end

                            puts "full_name = #{data["full_name"]}, created_at = #{data["created_at"]}, i = #{i}}"
                            sheet1.row(i + 1)[0] = data["full_name"]
                            sheet1.row(i + 1)[1] = data["html_url"]
                            sheet1.row(i + 1)[2] = data["description"]
                            sheet1.row(i + 1)[3] = data["forks_count"]
                            sheet1.row(i + 1)[4] = data["created_at"]
                            sheet1.row(i + 1)[5] = data["updated_at"]
                            sheet1.row(i + 1)[6] = data["pushed_at"]
                            sheet1.row(i + 1)[7] = data["stargazers_count"]
                            sheet1.row(i + 1)[8] = data["subscribers_count"]
                            sheet1.row(i + 1)[9] = data["open_issues_count"]
                            sheet1.row(i + 1)[10] = data["fork"]
                            sheet1.row(i + 1)[11] = data["has_wiki"]
                            sheet1.row(i + 1)[12] = data["has_pages"]
                            sheet1.row(i + 1)[13] = data["archived"]
                            sheet1.row(i + 1)[14] = data["disabled"]
                            sheet1.row(i + 1)[16] = data["language"]
                            sheet1.row(i + 1)[17] = openrank_sum
                            sheet1.row(i + 1)[18] = activity_sum

                            if data["license"] 
                                license = data["license"]
                                name = license["name"]
                                sheet1.row(i + 1)[15] = name
                            end

                            if i == names.count - 1
                                puts "excel 已经导出成功, 请查看桌面"
                                #在指定路径下面创建表格，并写book对象
                                book.write "/Users/summerxx/Desktop/rubyExcel/summerxx专属表.xls"
                                # DingDing.send_markdown("excel导出完成", "请查看桌面summerxx, #{username}表导出成功啦")
                            end
                        }
                    }
                end
            }
        end
    end
}


    
