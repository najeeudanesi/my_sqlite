require "readline"
require "./my_sqlite_request.rb"

class MySqliteCli

        def bufferCut(buffer, value)
            return buffer.split(value)
        end

        def stripQuotes(value)
            val = value.chop
            val[0]=""
            return val
        end

        def getWhereStatement(arr)

            data = {}
            i = arr.index("WHERE")
            i += 1
            field =""
            
            if arr[i] != nil
            field = arr[i]
            end

            valueOfWhere = arr [i +2]
            valueOfWhere = stripQuotes(valueOfWhere)

            if valueOfWhere != nil
                data[field] = valueOfWhere
            end
            return data
        end


        def whereInstance(columnName)
        conditions = getWhereStatement(@requestArr)
        @field = conditions.keys[0]
        @value = conditions.values[0]
        @request = MySqliteRequest.new().from(@tableName).select(columnName).where(@field, @value).run()

        end

        def orderInstance (columnName)
            @i = @requestArr.index("BY") + 1
            colName = @requestArr[@i]
            order = @requestArr[@i + 1]
            @request =  MySqliteRequest.new().from(@tableName).select(columnName).order(order, colName).run()
        end

        def joinInstance (columnName)
            @i = @requestArr.index("JOIN") + 1
            joinedTable = @requestArr[@i]  + ".csv"
            @i = @requestArr.index("ON") + 1
            colDbA = @requestArr[@i].split(".")[1]
            colDbB = @requestArr[@i + 2].split(".")[1]
            
            @request =  MySqliteRequest.new().from(@tableName).select(columnName).join(colDbA, joinedTable, colDbB).run()
            
        end



        def getSelectStatement(buffer)
            @requestArr = bufferCut(buffer, " ")
            columnName = nil
            @tableName = nil
            @field = nil
            @value = nil
            @request = nil

            @i = 1

            columnName = @requestArr[@i]

            if columnName.include? ","
                columnName = columnName.split(",")
            end
            
            @i = @requestArr.index("FROM") + 1

            @tableName = @requestArr[@i] + ".csv"

            @i = @i + 1

            if @requestArr.include? "WHERE"
                whereInstance( columnName)
            elsif @requestArr.include? "JOIN"
                joinInstance( columnName)

            elsif @requestArr.include? "ORDER"
                orderInstance( columnName)
            else 
                @request = MySqliteRequest.new().from(@tableName).select(columnName).run()

            end

            print @request
            puts ""

        end

        def createHash(tableName, data)
            hash = {}
        
            
            table = MySqliteRequest.new().csv_to_hash(tableName)
            heads = table[0].keys
            i=0

            heads.each do |head|
            hash.store(head, data[i])
            i +=1
            end

            return hash
        end

        def getInsertStatement(buffer)
            requestArr = bufferCut(buffer, " ")
            tableName = requestArr[2] + ".csv"
            
            
            values = bufferCut(buffer, "(")
            data = values[1].chop.split(",")

            newData = createHash(tableName, data)


            request = MySqliteRequest.new().insert(tableName).values(newData).run()

        end

        def getUpdateStatement(buffer)
            requestArr = bufferCut(buffer, " ")
            i = 1
            tableName = requestArr[i] + ".csv"

            i = requestArr.index("SET") 
            i +=1
            data = {}

            if requestArr[i] != nil
                while requestArr[i] != "WHERE"

                    key = requestArr[i]
                    val = requestArr[i + 2]
                    newVal = val.split("").last 

                    if newVal== ","
                        val= val.chop
                    end

                    val = stripQuotes(val)
                    data[key] = val
                    i = i +3
                end
            end
            condition = getWhereStatement(requestArr)
            field = condition.keys[0]
            value = condition.values[0]



            request = MySqliteRequest.new().update(tableName).values(data).where(field, value).run


        end

        def getDeleteStatement(buffer)
            requestArr = bufferCut(buffer, " ")
            i = requestArr.index("DELETE") 
            i += 2

            tableName = requestArr[i] + ".csv"
            condition = getWhereStatement(requestArr)
        
            value = condition.values[0]  
            field = condition.keys[0]

            request = MySqliteRequest.new().delete().from(tableName).where(field, value).run()
        end


        def readReq(buffer)

        req = buffer.split.first
            if req == "SELECT"
                getSelectStatement(buffer)
            elsif req =="INSERT"
                getInsertStatement(buffer)
            elsif req == "UPDATE"
                getUpdateStatement(buffer)
            elsif req == "DELETE"
                getDeleteStatement(buffer) 
            else 
                print "wrong request! \n"
            end
        end


        def readInput
            while buffer = Readline.readline("my_sqlite_cli> ", true)
                if buffer == "quit"
                    break
                end

                readReq(buffer)
            end
            return nil
        end

end

MySqliteCli.new().readInput()