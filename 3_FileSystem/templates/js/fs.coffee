window.global = {
    wd: '/'
    ls: []

    editingFile: ''

    clipFromPath: ''

    clipMethod: null # or 'duplicate' or 'move'

    errDict: {
      '-404': '文件不存在。'
      '-505': '文件已存在。'
      '-506': '找不到目录。'
      '-401': '复制或移动的文件不存在。'
    }

    openfile: (path)->
      $.ajax {
        url: '/operation'
        type: 'POST'
        data:
          operation: 'open'
          file: path
        dataType: 'json'
        success: (data)->
          console.log 'Response Received!'
          console.log data
          $('#ls-view').empty()
          $('#path-view').empty()

          ## Parent Folder
          parent_path = window.global.wd.substring 0, (window.global.wd.length - 1)
          console.log 'parent_path: ' + parent_path
          window.global.wd = path + '/'

          if window.global.wd isnt '/' then $('#ls-view').append '<tr><td><span class="glyphicon glyphicon-folder-close" aria-hidden="true"></span></td><td><a href="#" onclick="window.global.returnParent()">..</a></td><td> </td><td> </td><td> </td><td> </td><td> </td></tr>'

          ## Iteration
          if data['files'].length > 0 then  (
            tp = data['files'][i]['type']
            typeText = ''
            if tp is 'd' then (
              typeText = '<span class="glyphicon glyphicon-folder-close" aria-hidden="true"></span>'
            ) else (
              typeText = '<span class="glyphicon glyphicon-file" aria-hidden="true"></span>'
            )

            if data['files'][i]['size'] > 1000000 then (
              sizeText = (data['files'][i]['size'] / 1000000).toString() + ' M'
            ) else if data['files'][i]['size'] > 1000 then (
              sizeText = (data['files'][i]['size'] / 1000).toString() + ' K'
            ) else (
              sizeText = data['files'][i]['size'].toString()
            )

            if tp is 'd' then (
              sizeText = ' '
              namespan = '<a href="#" onclick="window.global.openfile(\'' +
                (path or '') + '/' + data['files'][i]['name'] +
                '\')">' + data['files'][i]['name'] + '</a>'
            ) else (
              namespan = '<a href="#" data-toggle="modal" data-target="#myModal" onclick="window.global.editfile(\'' +
                (path or '') + '/' + data['files'][i]['name'] +
                '\')">' + data['files'][i]['name'] + '</a>'
            )

            operation_text = '<a href="#" onclick="window.global.deleteFile(\'' + parent_path + '/' + data['files'][i]['name'] + '\')"><span class="glyphicon glyphicon-remove" aria-hidden="true"></span></a>'
            operation_text += '&nbsp;&nbsp;&nbsp;'
            operation_text += '<a href="#" onclick="window.global.duplicateFile(\'' + parent_path + '/' + data['files'][i]['name'] + '\')"><span class="glyphicon glyphicon-duplicate" aria-hidden="true"></span></a>'
            operation_text += '&nbsp;&nbsp;&nbsp;'
            operation_text += '<a href="#" onclick="window.global.moveFile(\'' + parent_path + '/' + data['files'][i]['name'] + '\')"><span class="glyphicon glyphicon-scissors" aria-hidden="true"></span></a>'

            $('#ls-view').append '<tr>' +
                '<td>' + typeText + '</td>' +
                '<td>' + namespan + '</td>' +
                '<td>' + sizeText + '</td>' +
                '<td>' + data['files'][i]['lac'] + '</td>' +
                '<td>' + data['files'][i]['lup'] + '</td>' +
                '<td>' + data['files'][i]['idx'] + '</td>' +
                '<td>' + operation_text  + '</td>' + '</tr>'
          ) for i in [0..data['files'].length - 1]

          ## Edit create folder div
          $('#create-folder-parent').empty()
          $('#create-folder-parent').append(window.global.wd)
          $('#path-view').append window.global.wd
          0
      }

    returnParent: ()->
      ## Parent Folder
      if window.global.wd is '/' then return
      parent_path = window.global.wd.substring 0, (window.global.wd.length - 1)
      parent_path = parent_path.substring 0, parent_path.lastIndexOf '/'
      console.log 'parent_path: ' + parent_path
      $.ajax({
        url: '/operation'
        type: 'POST'
        data: {
          operation: 'open'
          file: parent_path
        }
        dataType: 'json'
        success: (data)->
          console.log 'Response Received!'
          console.log data
          $('#ls-view').empty()
          $('#path-view').empty()
          $('#path-view').append parent_path + '/'
          window.global.wd = parent_path + '/'

          if window.global.wd isnt '/' then $('#ls-view').append '<tr><td><span class="glyphicon glyphicon-folder-close" aria-hidden="true"></span></td><td><a href="#" onclick="window.global.returnParent()">..</a></td><td> </td><td> </td><td> </td><td> </td><td> </td></tr>'

          ## Iteration
          if data['files'].length > 0 then  (
            tp = data['files'][i]['type']
            typeText = ''
            if tp is 'd' then (
              typeText = '<span class="glyphicon glyphicon-folder-close" aria-hidden="true"></span>'
            ) else (
              typeText = '<span class="glyphicon glyphicon-file" aria-hidden="true"></span>'
            )

            if data['files'][i]['size'] > 1000000 then (
              sizeText = (data['files'][i]['size'] / 1000000).toString() + ' M'
            ) else if data['files'][i]['size'] > 1000 then (
              sizeText = (data['files'][i]['size'] / 1000).toString() + ' K'
            ) else (
              sizeText = data['files'][i]['size'].toString()
            )

            if tp is 'd' then (
              sizeText = ' '
              namespan = '<a href="#" onclick="window.global.openfile(\'' +
                parent_path + '/' + data['files'][i]['name'] +
                '\')">' + data['files'][i]['name'] + '</a>'
            ) else (
              namespan = '<a href="#" data-toggle="modal" data-target="#myModal" onclick="window.global.editfile(\'' +
                parent_path + '/' + data['files'][i]['name'] +
                '\')">' + data['files'][i]['name'] + '</a>'
            )

            operation_text = '<a href="#" onclick="window.global.deleteFile(\'' + parent_path + '/' + data['files'][i]['name'] + '\')"><span class="glyphicon glyphicon-remove" aria-hidden="true"></span></a>'
            operation_text += '&nbsp;&nbsp;&nbsp;'
            operation_text += '<a href="#" onclick="window.global.duplicateFile(\'' + parent_path + '/' + data['files'][i]['name'] + '\')"><span class="glyphicon glyphicon-duplicate" aria-hidden="true"></span></a>'
            operation_text += '&nbsp;&nbsp;&nbsp;'
            operation_text += '<a href="#" onclick="window.global.moveFile(\'' + parent_path + '/' + data['files'][i]['name'] + '\')"><span class="glyphicon glyphicon-scissors" aria-hidden="true"></span></a>'

            $('#ls-view').append '<tr>' +
                '<td>' + typeText + '</td>' +
                '<td>' + namespan + '</td>' +
                '<td>' + sizeText + '</td>' +
                '<td>' + data['files'][i]['lac'] + '</td>' +
                '<td>' + data['files'][i]['lup'] + '</td>' +
                '<td>' + data['files'][i]['idx'] + '</td>' +
                '<td>' + operation_text + '</td>' + '</tr>'
          ) for i in [0..data['files'].length - 1]

          ## Edit create folder div
          $('#create-folder-parent').empty()
          $('#create-folder-parent').append(window.global.wd)
          0
      })

    editfile: (filepath)->
      window.global.editingFile = ''
      console.log 'Editing file: ' + filepath
      $('#edit-file-title').empty()
      $('#edit-file-title').append('编辑文件：' + filepath)
      $('#edit-file-content').val('')
      $.ajax({
        url: '/operation'
        type: 'POST'
        data: {
          operation: 'read'
          path: filepath
        }
        dataType: 'json'
        success: (res)->
          $('#edit-file-content').val(res['content'])
          window.global.editingFile = filepath
      })

    deleteFile: (filepath)->
      conf = confirm '是否确定删除此文件？'
      if conf isnt true then return 0
      $.ajax({
        url: '/operation'
        type: 'POST'
        data: {
          operation: 'delete'
          path: filepath
        }
        dataType: 'json'
        success: (res)->
          if res.code isnt 0 then alert '哎呀，删除失败：' + window.global.errDict[code]; return 0
          if filepath is window.global.clipFromPath then (
            window.global.clipMethod = null
            window.global.clipFromPath = ''
            $('#clip-parent').empty()
            $('#clip-parent').val('/')
            $('#clip-dest-filename').val('')
            $('#clip-fieldset').attr('disabled', true)
            $('#clip-button').empty()
            $('#clip-button').append('无文件')
          )
          window.global.openfile(window.global.wd.substring(0, window.global.wd.length - 1))
          0
      })
      return 0

    duplicateFile: (filepath)->
      window.global.clipFromPath = filepath
      window.global.clipMethod = 'duplicate'
      $('#clip-parent').empty()
      $('#clip-parent').append(filepath)
      $('#clip-fieldset').removeAttr('disabled')
      $('#clip-button').empty()
      $('#clip-button').append('复制到当前目录下')

    moveFile: (filepath)->
      window.global.clipFromPath = filepath
      window.global.clipMethod = 'move'
      $('#clip-parent').empty()
      $('#clip-parent').append(filepath)
      $('#clip-fieldset').removeAttr('disabled')
      $('#clip-button').empty()
      $('#clip-button').append('移动到当前目录下')

    clip: ()->
      if window.global.clipMethod is null then return 0

      newFileName = $('#clip-dest-filename').val()
      if newFileName is '' then (
        alert '文件或文件夹名不能为空…… _(:з」∠)_'
        return 0
      )
      if newFileName.indexOf('/') isnt -1 or
        newFileName.indexOf('*') isnt -1 or
        newFileName.indexOf('?') isnt -1 or
        newFileName.indexOf('<') isnt -1 or
        newFileName.indexOf('>') isnt -1 or
        newFileName.indexOf(':') isnt -1 or
        newFileName.indexOf('|') isnt -1 or
        newFileName.indexOf('\\') isnt -1 or
        newFileName.indexOf('"') isnt -1 then (
          alert '请确定你的文件或文件夹名是合法的…… _(:з」∠)_'
          return 0
      )
      if newFileName.lastIndexOf('.') is (newFileName.length - 1) then alert '请确定你的文件或文件夹名是合法的…… _(:з」∠)_'; return 0
      newFilePath = window.global.wd + newFileName
      $.ajax({
        url: '/operation'
        type: 'POST'
        data: {
          operation: 'clip'
          method: window.global.clipMethod
          srcPath: window.global.clipFromPath
          destPath: newFilePath
        }
        dataType: 'json'
        success: (res)->
          code = res.code
          if code isnt 0 then (
            alert '哎呀，出错了：\n' + (window.global.errDict[code.toString()] or ("未知错误……" + code.toString()) )
            return 1
          ) else (
            $('#clip-dest-filename').val('')
            if window.global.clipMethod is 'move' then (
              window.global.clipMethod = null
              window.global.clipFromPath = ''
              $('#clip-parent').empty()
              $('#clip-parent').val('/')
              $('#clip-fieldset').attr('disabled', true)
              $('#clip-button').empty()
              $('#clip-button').append('无文件')
            )
            window.global.openfile(window.global.wd.substring(0, window.global.wd.length - 1))
            return 0
          )
      })
}

$(document).ready ()->
  ## Initialization root
  window.global.openfile('')

  ## bind onclick event functions
  $('#btn-new-folder').click (event)->
    filename = $('#create-file-input').val()
    # Check validation
    if filename is '' then alert '文件或文件夹名不能为空…… _(:з」∠)_'; return
    if filename.indexOf('/') isnt -1 or
      filename.indexOf('*') isnt -1 or
      filename.indexOf('?') isnt -1 or
      filename.indexOf('<') isnt -1 or
      filename.indexOf('>') isnt -1 or
      filename.indexOf(':') isnt -1 or
      filename.indexOf('|') isnt -1 or
      filename.indexOf('\\') isnt -1 or
      filename.indexOf('"') isnt -1
      then alert '请确定你的文件或文件夹名是合法的…… _(:з」∠)_'; return
    if filename.lastIndexOf('.') is (filename.length - 1) then alert '请确定你的文件或文件夹名是合法的…… _(:з」∠)_'; return
    # get new file url
    newFileUrl = window.global.wd + $('#create-file-input').val()
    console.log('Creating folder: %s', newFileUrl)

    $.ajax({
      url: '/operation'
      type: 'POST'
      data: {
        operation: 'create'
        path: newFileUrl
        type: 'd'
      }
      dataType: 'json'
      success: (res)->
        code = res.code
        if code isnt 0 then (
          alert '哎呀，出错了：\n' + (window.global.errDict[code.toString()] or ("未知错误……" + code.toString()) )
          return 1
        ) else (
          $('#create-file-input').val('')
          window.global.openfile(window.global.wd.substring(0, window.global.wd.length - 1))
          return 0
        )
    })

  $('#btn-new-regfile').click (event)->
    filename = $('#create-file-input').val()
    # Check validation
    if filename is '' then alert '文件或文件夹名不能为空…… _(:з」∠)_'; return
    if filename.indexOf('/') isnt -1 or
      filename.indexOf('*') isnt -1 or
      filename.indexOf('?') isnt -1 or
      filename.indexOf('<') isnt -1 or
      filename.indexOf('>') isnt -1 or
      filename.indexOf(':') isnt -1 or
      filename.indexOf('|') isnt -1 or
      filename.indexOf('\\') isnt -1 or
      filename.indexOf('"') isnt -1
      then alert '请确定你的文件或文件夹名是合法的…… _(:з」∠)_'; return
    if filename.lastIndexOf('.') is (filename.length - 1) then alert '请确定你的文件或文件夹名是合法的…… _(:з」∠)_'; return
    # get new file url
    newFileUrl = window.global.wd + $('#create-file-input').val()
    console.log('Creating file: %s', newFileUrl)

    $.ajax({
      url: '/operation'
      type: 'POST'
      data: {
        operation: 'create'
        path: newFileUrl
        type: '-'
      }
      dataType: 'json'
      success: (res)->
        code = res.code
        if code isnt 0 then (
          alert '哎呀，出错了：\n' + (window.global.errDict[code.toString()] or ("未知错误……" + code.toString()) )
          return 1
        ) else (
          $('#create-file-input').val('')
          window.global.openfile(window.global.wd.substring(0, window.global.wd.length - 1))
          return 0
        )
    })

  $('#edit-file-btn-close').click (event)->
    window.global.editingFile = ''
    window.global.openfile(window.global.wd.substring(0, window.global.wd.length - 1))

  $('#edit-file-btn-save').click (evnet)->
    filepath = window.global.editingFile
    writeContent = $('#edit-file-content').val() or ''
    console.log 'Writing file: ' + filepath
    console.log 'Writing Content: ' + writeContent
    $.ajax({
      url: '/operation'
      type: 'POST'
      dataType: 'json'
      data: {
        operation: 'write'
        path: filepath
        content: writeContent
      }
      success: (res)->
        code = res.code
        if code is 0 then alert '保存成功~' else (
          alert '哎呀，保存失败：' + window.global.errDict[code]
        )
        return 0
    })
    return 0

  return 0