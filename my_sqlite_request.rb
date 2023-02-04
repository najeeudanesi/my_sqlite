require 'csv'

class MySqliteRequest
  def initialize
    @request = []
    @selecetedColumns = []
    @byCriteria = []
    @sortedTable = []
    @tableName = []
    @csvName = []
    @tableHeads = []
    @checkMethod = ''
    self
  end

  def delete_from_file(file_name, col_name, val)
    rows = CSV.read(file_name, headers: true)
    rows.delete_if { |row| row[col_name] == val }
    CSV.open(file_name, 'w', headers: true) do |csv|
      csv << rows.headers
      rows.each { |row| csv << row }
    end
  end

  def joinTables(table_a, table_b, column_on_db_a, column_on_db_b)
    tempTableA = []
    tempTableB = []
    joinedTable = []

    table_a.each do |hash|
      table_b.each do |h|
        if hash[column_on_db_a] == h[column_on_db_b]
          tempTableA.push(hash)
          tempTableB.push(h)
        end
      end
    end
    tempTableA.each do |hash|
      newHash = Hash.new(0)
      tempTableB.each do |h|
        newHash = hash.merge!(h.select { |k, _| !hash.has_key? k })
      end
      joinedTable.push(newHash)
    end
    joinedTable
  end

  def update_op(new_data)
    @newData = new_data
  end

  def insert_op(list_of_hashes, new_hash)
    if new_hash.class == Array
      new_hash.each do |data|
        list_of_hashes << data
      end
    else
      list_of_hashes << new_hash
    end
    @request = list_of_hashes
  end

  def write_to_file(list_of_hashes, db_name)
    CSV.open(db_name, 'w', headers: true) do |csv|
      return if list_of_hashes.length == 0

      csv << list_of_hashes[0].keys # how to fix this???
      list_of_hashes.each do |hash|
        csv << CSV::Row.new(hash.keys, hash.values)
      end
    end
  end

  def readFromCSVFile(table_name)
    table = nil
    filename_db = table_name
    if filename_db
      table = CSV.foreach(filename_db, headers: true).map { |row| row.to_h }
    else
      print 'No such file'
      return nil
    end
    table
  end

  def csv_to_hash(csv_file)
    @tableName = csv_file
    table = readFromCSVFile(csv_file)
    table
  end

  def where_select(column_name, criteria)
    self if !column_name || !criteria
    if @column_name.class == Array
      # puts @column_name
      whereArr = []
      @table.map do |hash|
        @column_name.each do |n|
          whereArr << hash[n] if hash[column_name] == criteria
        end
      end

      result = whereArr.each_slice(2).map do |a, b|
        { @column_name[0] => a, @column_name[1] => b }
      end
      # puts "result = #{result}"
      @request = result
      # puts "request = #{@request}"

    else
      @table.map do |hash|
        @byCriteria << hash[@column_name] if hash[column_name] == criteria
      end
      newArr = []
      @byCriteria.each do |val|
        ha = { @column_name => val }
        newArr << ha
      end
      @request = newArr
    end
  end

  def where_update(column_name, criteria)
    self if !column_name || !criteria
    key = @newData.keys
    val = @newData.values
    len = key.length
    elem = @request.find_all { |hash| hash[column_name] == criteria }
    (0..len - 1).each do |i|
      elem.each do |hash|
        hash[key[i]] = val[i]
      end
    end
    rows = CSV.read(@file_name, headers: true)
    CSV.open(@file_name, 'w', headers: true) do |csv|
      csv << rows.headers
      @request.each { |row| csv << row }
    end
    #update_file(@file_name, column_name, criteria)
  end

  def where_delete(column_name, criteria)
    index = 0
    @request.each do |hash|
      # puts "hash = #{hash}"
      index = @request.index(hash) if hash[column_name] == criteria
    end
    @request.delete_at(index)
    delete_from_file(@csvName, column_name, criteria)
  end

  def from(table_name)
    @table = csv_to_hash(table_name)
    @csvName = table_name
    @tableHeads << @table[0].keys
    # puts @tableHeads
    @request = @table
    @request
    self
  end

  def select(column_name)
    @column_name = column_name
    @checkMethod = 'select'
    if column_name == '*'
      @selecetedColumns = @table
    else
      @table.map do |hash|
        newHash = nil
        newHash = if column_name.class == Array
                    hash.select { |key, _| column_name.include? key }
                  else
                    hash.select { |key, _| key == column_name }
                  end
        @selecetedColumns << newHash
      end
    end
    @request = @selecetedColumns
    # puts @request
    self
  end

  def where(column_name, criteria)
    # select" update, delete
    if @checkMethod == 'select'
      where_select(column_name, criteria)
    elsif @checkMethod == 'update'
      where_update(column_name, criteria)
    elsif @checkMethod == 'delete'
      where_delete(column_name, criteria)
    end
    self
  end

  def insert(file_name)
    @checkMethod = 'insert'
    @file_name = file_name
    table_hash = csv_to_hash(file_name)
    @request = table_hash
    self
  end

  def values(data)
    @data = data
    if @checkMethod == 'insert'
      insert_op(@request, @data)
      write_to_file(@request, @file_name)
    elsif @checkMethod == 'update'
      update_op(@data)
    end
    # @checkMethod = ''
    self
  end

  def update(file_name)
    @file_name = file_name
    @checkMethod = 'update'
    table_hash = csv_to_hash(file_name)
    @request = table_hash
    self
  end

  def delete
    @checkMethod = 'delete'
    self
  end

  def join(column_on_db_a, filename_db_b, column_on_db_b)
    puts column_on_db_a
    @joined_table = []
    @second_table = readFromCSVFile(filename_db_b)
    @joined_table = joinTables(@table, @second_table, column_on_db_a, column_on_db_b)
    @request = @joined_table
    self
  end

  def order(order, column_name)
    @sortedTable = @request.sort_by { |k| k[column_name] }
    @sortedTable.reverse! if order == 'DESC'
    @request = @sortedTable
    self
  end

  def set(value)
    @data = value

    return self
end

  def run
    puts @request
  end
end


