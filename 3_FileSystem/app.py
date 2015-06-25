#!/usr/bin/env python
# -*-coding:utf-8-*-

__author__ = 'JoshOY'

import tornado
import tornado.web
import tornado.ioloop
import json
import os
import datetime
from pyfs import FileSystem, INode, Block, Const

fs = FileSystem()



class MainHandler(tornado.web.RequestHandler):
    def data_received(self, chunk):
        print chunk

    @tornado.web.asynchronous
    def get(self):
        used_space = 0
        for inode in fs.inode_list:
            used_space += inode.file_size
        block_size, block_total = Const.BLOCK_SIZE, Const.BLOCK_TOTAL_NUM
        percent_used = str(float(used_space) * 100 / float(block_size * block_total)) + '%'
        self.render('templates/ui_index.html',
                    block_size=block_size,
                    block_num_total=block_total,
                    total_space=block_size * block_total,
                    used_space=used_space,
                    percent_used=percent_used)
        # self.finish()

class ExplorerHandler(tornado.web.RequestHandler):
    def data_received(self, chunk):
        print chunk

    @tornado.web.asynchronous
    def get(self):
        self.render('templates/ui_explorer.html')

class OperationHandler(tornado.web.RequestHandler):
    def data_received(self, chunk):
        print chunk

    @tornado.web.asynchronous
    def post(self):
        operation = self.get_argument('operation')

        if operation == 'open':
            open_dir = self.get_argument('file')
            print 'Going for open: ' + open_dir
            # TODO: 找到文件夹的inode然后返回下面的所有文件
            if open_dir == '/' or open_dir == '':
                dir_open = fs.inode_list[0]
            else:
                dir_open = fs.find_inode(open_dir)
            ls_idx = dir_open.get_include_inodes_idx()
            res = {'files':[]}
            for idx in ls_idx:
                child_inode = fs.inode_list[idx]
                lac_tuple = datetime.datetime.fromtimestamp(child_inode.last_time_access).timetuple()[0:6]
                lup_tuple = datetime.datetime.fromtimestamp(child_inode.last_time_update).timetuple()[0:6]
                res['files'].append({
                    'idx': child_inode.idx,
                    'type': child_inode.file_type,
                    'name': child_inode.file_name,
                    'size': child_inode.file_size,
                    'lac': '%d-%d-%d %d:%d:%d' % lac_tuple,
                    'lup': '%d-%d-%d %d:%d:%d' % lup_tuple,
                })
            self.write(json.dumps(res, encoding='utf-8'))
            self.finish()
            # TODO END
        elif operation == 'create':
            # TODO: 创建文件夹或文件
            new_file_path = self.get_argument('path')
            file_type = self.get_argument('type')
            ret_code = fs.create(new_file_path, ftype=file_type)
            if ret_code == 0:
                fs.save()
            res = {
                'code': ret_code
            }
            self.write(json.dumps(res, encoding='utf-8'))
            self.finish()
            # TODO END
        elif operation == 'read':
            # TODO: 读取文件内容
            file_path = self.get_argument('path')
            file_to_read = fs.find_inode(file_path)
            content = file_to_read.read()
            res = {
                'content': content
            }
            self.write(json.dumps(res, encoding='utf-8'))
            self.finish()
            # TODO END
        elif operation == 'write':
            # TODO：写文件
            file_path = self.get_argument('path')
            write_content = self.get_argument('content')
            file_to_write = fs.find_inode(file_path)
            code = file_to_write.write(write_content)
            if code == 0:
                file_to_write.update_size()
                fs.save()
            res = {
                'code': code
            }
            self.write(json.dumps(res, encoding='utf-8'))
            self.finish()
            # TODO END
        elif operation == 'delete':
            # TODO: 删除文件或目录
            file_path = self.get_argument('path')
            code = fs.delete(file_path)
            if code == 0:
                fs.save()
            res = {
                'code': code
            }
            self.write(json.dumps(res, encoding='utf-8'))
            self.finish()
            # TODO END
        elif operation == 'clip':
            # TODO: 复制/移动文件或目录
            src_file_path = self.get_argument('srcPath')
            dest_file_path = self.get_argument('destPath')
            method = self.get_argument('method')
            if method == 'duplicate':
                code = fs.copy(src_file_path, dest_file_path)
            elif method == 'move':
                code = fs.move(src_file_path, dest_file_path)
            else:
                code = -999
            res = {
                'code': code
            }
            fs.save()
            self.write(json.dumps(res, encoding='utf-8'))
            self.finish()


class FSApplication(tornado.web.Application):
    def __init__(self):
        handlers = [
            (r'/', MainHandler),
            (r'/explorer', ExplorerHandler),
            (r'/operation', OperationHandler),
        ]
        settings = {
            "debug": True,
            "static_path": os.path.join(os.path.dirname(__file__), "templates")
        }
        tornado.web.Application.__init__(self, handlers, **settings)

application = FSApplication()

if __name__ == '__main__':
    application.listen(8888)
    tornado.ioloop.IOLoop.instance().start()