#!/usr/bin/env python
# -*-coding:utf-8-*-
__author__ = 'JoshOY'

import json, time, datetime, copy

# Global Variables

# FS Part


class Const:
    BLOCK_TOTAL_NUM = 4096
    BLOCK_SIZE      = 128

    INODE_TOTAL_NUM = 4096

    OPERATION_DONE = 0
    ERROR_FILE_NOT_FOUND = -404
    ERROR_FILE_HAS_EXIST = -505
    ERROR_DIR_NOT_FOUNT = -506

    ERROR_SRC_FILE_NOT_FOUND = -401
    ERROR_DEST_FILE_EXIST = -402

    ERROR_BLOCK_OVERFLOW = -606
    ERROR_FILE_IS_NOT_DIR = -607


class INode:
    def __init__(self, json_obj):
        self.idx = json_obj['idx']
        self.file_name = json_obj['name']
        self.block_using = json_obj['block_using']
        self.file_type = json_obj['type']
        self.file_size = json_obj['size']
        self.last_time_access = json_obj['lac']
        self.last_time_update = json_obj['lup']
        self.parent_idx = json_obj['parent']

    def __str__(self):
        return '{"idx":%s,"name":"%s","block_using":%s,"type":"%s","size":%d,"last_time_access":%s,"last_time_update":%s}' % (
            self.idx, self.file_name, self.block_using, self.file_type, self.file_size, self.last_time_access, self.last_time_update,
        )

    def parse_dict(self):
        return {
            'idx': self.idx,
            'name': self.file_name,
            'block_using': self.block_using,
            'type': self.file_type,
            'size': self.file_size,
            'lac': self.last_time_access,
            'lup': self.last_time_update,
            'parent': self.parent_idx,
        }

    def read(self):
        self.last_time_access = time.time()
        ret = ''
        for bid in self.block_using:
            ret += FileSystem.block_list[bid].readbytes()
        return ret

    def clear(self):
        self.last_time_update = time.time()
        self.last_time_access = time.time()
        for i, idx in enumerate(self.block_using):
            FileSystem.block_list[idx].clear()
            if i is 0:
                FileSystem.block_list[idx].usedby = self.idx
            self.block_using = self.block_using[0:1]
            self.file_size = 0

    def delete(self):
        if self.file_type == 'd':
            ls = self.get_include_inodes_idx()
            for child_idx in ls:
                FileSystem.inode_list[child_idx].delete()
        self.clear()
        parent = FileSystem.inode_list[self.parent_idx]
        file_ls = parent.get_include_inodes_idx()
        del file_ls[file_ls.index(self.idx)]
        parent.write(json.dumps(file_ls, encoding='utf-8'))
        self.parent_idx = None
        self.file_name = ''
        self.file_type = None
        self.block_using = []
        self.file_size = 0

    def write(self, buffer):
        self.clear()
        return self.write_append(buffer, block_to_write_idx=self.block_using[0])

    def write_append(self, buffer, block_to_write_idx=None):
        self.last_time_update = time.time()
        self.last_time_access = time.time()
        remain_buffer = buffer
        if block_to_write_idx is None:
            block_to_write = FileSystem.block_list[self.block_using[-1]]
        else:
            block_to_write = FileSystem.block_list[block_to_write_idx]

        # Case not full
        if (Const.BLOCK_SIZE - block_to_write.usedlen) >= len(remain_buffer):
            block_to_write.writebytes(block_to_write.data[0:block_to_write.usedlen] + remain_buffer)
            return Const.OPERATION_DONE

        # Case overflow
        # Start to write
        while (Const.BLOCK_SIZE - block_to_write.usedlen) < len(remain_buffer):
            length_to_write = Const.BLOCK_SIZE - block_to_write.usedlen
            block_to_write.writebytes(block_to_write.data[0:block_to_write.usedlen] \
                                      + remain_buffer[0:length_to_write] )
            remain_buffer = remain_buffer[length_to_write:]
            for block in FileSystem.block_list:
                if block.usedby is None:
                    # Occupy this block
                    block.clear()
                    block.usedby = self.idx
                    self.block_using.append(block.idx)
                    # Full write this block
                    block_to_write = block
                    break
        block_to_write.writebytes(remain_buffer)
        self.update_size()
        return Const.OPERATION_DONE

    def update_size(self):
        self.file_size = (len(self.block_using) - 1) * Const.BLOCK_SIZE + FileSystem.block_list[self.block_using[-1]].usedlen

    def get_include_inodes_idx(self):
        if self.file_type != u'd':
            return Const.ERROR_FILE_IS_NOT_DIR
        else:
            list_str = self.read()
            idx_list = json.loads(list_str)
            return idx_list

    def dir_append_child_idx(self, idx):
        if self.file_type != u'd':
            return Const.ERROR_FILE_IS_NOT_DIR
        else:
            child_ls = self.get_include_inodes_idx()
            child_ls.append(idx)
            self.write(json.dumps(child_ls, encoding='utf-8'))

    def dir_remove_child_idx(self, idx):
        if self.file_type != u'd':
            return Const.ERROR_FILE_IS_NOT_DIR
        else:
            child_ls = self.get_include_inodes_idx()
            del child_ls[child_ls.index(idx)]
            self.write(json.dumps(child_ls, encoding='utf-8'))


class Block:
    def __init__(self, json_obj):
        self.idx  = json_obj['idx']         # data block index
        self.data = json_obj['data']        # data str
        self.usedby = json_obj['usedby']    # True/False
        self.usedlen = json_obj['usedlen']  # 0 ~ BLOCK_SIZE

    def parse_dict(self):
        return {
            'idx': self.idx,
            'data': self.data,
            'usedby': self.usedby,
            'usedlen': self.usedlen,
        }

    def readbytes(self, length=None):
        if length is None:
            return self.data[0:self.usedlen]
        else:
            return self.data[0:length]

    def writebytes(self, buffer):
        if len(buffer) > Const.BLOCK_SIZE:
            return Const.ERROR_BLOCK_OVERFLOW
        self.data = buffer + ('\0' * (Const.BLOCK_SIZE - len(buffer)))
        self.usedlen = len(buffer)
        return Const.OPERATION_DONE

    def clear(self):
        self.usedlen = 0
        self.data = '\0' * Const.BLOCK_SIZE
        self.usedby = None

class FileSystem:
    inode_list = []
    block_list = []

    def __init__(self):
        self.datafile = open('./fsdata.json', 'r')
        self.init()

    def init(self):
        alldata = self.datafile.read()
        try:
            data = json.loads(alldata)
            for json_obj in data['inode_data']:
                FileSystem.inode_list.append(INode(json_obj))
            for json_obj in data['block_data']:
                FileSystem.block_list.append(Block(json_obj))
            self.datafile.close()
            print 'FS init done.'
        except Exception:
            self.datafile.close()
            print 'Unable to read datafile. Formatting...'
            self._format_fs()

    def _format_fs(self):
        """
        Format the entire file system if nessesary.
        :return: 0
        """
        self.datafile = open('./fsdata.json', 'w')
        data = {
            'inode_data': [{
                'idx': 0,
                'name': '',
                'block_using': [0],
                'type': 'd',
                'size': 0,
                'lac': time.time(),
                'lup': time.time(),
                'parent': None,
            }],
            'block_data': [{
                'idx': 0,
                'data': '[]' + '\0' * (Const.BLOCK_SIZE - 2),
                'usedby': 0,
                'usedlen': 2,
            }],
        }
        for idx in xrange(Const.BLOCK_TOTAL_NUM):
            if idx == 0:
                continue
            block_data_new = {
                'idx': idx,
                'data': '\0' * Const.BLOCK_SIZE,
                'usedby': None,
                'usedlen': 0,
            }
            data['block_data'].append(block_data_new)
        for idx in xrange(Const.INODE_TOTAL_NUM):
            if idx == 0:
                continue
            inode_data_new = {
                'idx': idx,
                'name': '',
                'type': None,
                'size': 0,
                'block_using': [],
                'lac': time.time(),
                'lup': time.time(),
                'parent': None,
            }
            data['inode_data'].append(inode_data_new)
        self.datafile.write(json.dumps(data, encoding='utf-8'))
        self.datafile.close()
        self.datafile = None
        print 'Format done.'

        self.datafile = open('./fsdata.json', 'r')
        self.init()

        return 0

    def save(self):
        self.datafile = open('./fsdata.json', 'w')
        data = {
                'inode_data': [],
                'block_data': [],
        }
        for inode in self.inode_list:
            data['inode_data'].append(inode.parse_dict())
        for block in self.block_list:
            data['block_data'].append(block.parse_dict())
        self.datafile.write(json.dumps(data, encoding='utf-8'))
        self.datafile.close()
        print 'Save done.'

    def __del__(self):
        pass

    def create(self, path, ftype=u'-'):
        filename = path.split(u'/')[-1]
        # check TODO
        result = self.find_inode_idx(path)
        if result >= 0:
            return Const.ERROR_FILE_HAS_EXIST
        parent_idx = self.find_inode_idx(u'/'.join(path.split(u'/')[:-1]))
        if parent_idx < 0:
            return Const.ERROR_DIR_NOT_FOUNT
        parent = FileSystem.inode_list[parent_idx]
        if parent.file_type != u'd':
            return Const.ERROR_FILE_IS_NOT_DIR
        if ftype == u'-':
            for inode in FileSystem.inode_list:
                if inode.file_type is None:
                    inode.file_name = filename
                    inode.file_type = '-'
                    inode.file_size = 0
                    inode.last_time_access = time.time()
                    inode.last_time_update = time.time()
                    inode.parent_idx = parent.idx
                    for block in FileSystem.block_list:
                        if block.usedby is None:
                            inode.block_using = [block.idx]
                            block.usedby = inode.idx
                            break
                    break
            ls = parent.get_include_inodes_idx()
            ls.append(inode.idx)
            parent.write(
                json.dumps(ls, encoding='utf-8')
            )
            return Const.OPERATION_DONE
        elif ftype == u'd':
            for inode in FileSystem.inode_list:
                if inode.file_type is None:
                    inode.file_name = filename
                    inode.file_type = 'd'
                    inode.file_size = 2
                    inode.last_time_access = time.time()
                    inode.last_time_update = time.time()
                    inode.parent_idx = parent.idx
                    for block in FileSystem.block_list:
                        if block.usedby is None:
                            inode.block_using = [block.idx]
                            block.usedby = inode.idx
                            block.writebytes('[]')
                            break
                    break
            ls = parent.get_include_inodes_idx()
            ls.append(inode.idx)
            parent.write(
                json.dumps(ls, encoding='utf-8')
            )
            return Const.OPERATION_DONE
        self.save()

    def delete(self, path, parent_idx=None):
        inode_to_del = self.find_inode(path, parent_idx)
        if not isinstance(inode_to_del, INode):
            return inode_to_del
        else:
            inode_to_del.delete()
        return Const.OPERATION_DONE

    def copy(self, src, dest):
        src_idx = self.find_inode_idx(src, None)
        dest_exist = self.find_inode_idx(dest, None)
        if src_idx < 0:
            return Const.ERROR_SRC_FILE_NOT_FOUND
        if dest_exist >= 0:
            return Const.ERROR_DEST_FILE_EXIST
        # If OK:
        src_inode = self.inode_list[src_idx]
        self.create(dest, src_inode.file_type)
        dest_inode = self.find_inode(dest)
        dest_inode.write(src_inode.read())
        return Const.OPERATION_DONE

    def move(self, src, dest):
        src_idx = self.find_inode_idx(src, None)
        dest_exist = self.find_inode_idx(dest, None)
        if src_idx < 0:
            return Const.ERROR_SRC_FILE_NOT_FOUND
        if dest_exist >= 0:
            return Const.ERROR_DEST_FILE_EXIST
        inode = FileSystem.inode_list[src_idx]
        new_name = dest.split('/')[-1]
        try:
            old_parent_idx = inode.parent_idx
            inode.parent_idx = self.find_inode('/'.join(dest.split('/')[:-1]))
        except Exception:
            inode.parent_idx = old_parent_idx
            return Const.ERROR_DIR_NOT_FOUNT
        try:
            old_parent = self.inode_list[old_parent_idx]
            old_parent.dir_remove_child_idx(inode.idx)
            parent = self.inode_list[inode.parent_idx]
            parent.dir_append_child_idx(inode.idx)
            inode.file_name = new_name
        except Exception:
            return Const.ERROR_FILE_IS_NOT_DIR

    def find_inode_idx(self, path, parent_idx=None):
        if path is u'':
            return 0
        if parent_idx is None:
            if path == u'/' and FileSystem.inode_list[0].file_type == u'd':
                return 0
            elif path == u'/':
                return Const.ERROR_FILE_NOT_FOUND
            pl = path.split(u'/')
            if path[-1] is u'/':
                pl = pl[:-1]
            if not pl[0] == u'':  # if not '/'
                return Const.ERROR_DIR_NOT_FOUNT
            else:
                return self.find_inode_idx(u'./' + u'/'.join(pl[1:]), 0) # '/' always stays in idx 0
        else: # parent not None
            if path[0:2] != u'./':
                return Const.ERROR_DIR_NOT_FOUNT
            exist_files_idx = FileSystem.inode_list[parent_idx].get_include_inodes_idx()
            for inode_idx in exist_files_idx:
                inode = FileSystem.inode_list[inode_idx]
                if inode.file_name == path[2:].split(u'/')[0]:
                    return inode.idx if (len(path[2:].split(u'/')) is 1) \
                else self.find_inode_idx(u'./' + u'/'.join(path[2:].split(u'/')[1:]), inode.idx)
            return Const.ERROR_FILE_NOT_FOUND if (len(path[2:].split(u'/')) is 1) else Const.ERROR_DIR_NOT_FOUNT

    def find_inode(self, path, parent_idx=None):
        idx = self.find_inode_idx(path, parent_idx)
        if idx < 0:
            return idx
        return self.inode_list[idx]

if __name__ == '__main__':
    pass
    # fs = FileSystem()
    # print fs.find_inode_idx(u'/')
    # print fs.create(u'/usr', u'd')
    # print fs.create(u'/env', u'd')
    # print fs.create(u'/env/test.txt', u'-')
    # print fs.find_inode_idx(u'/env/test.txt')
    # f = fs.inode_list[fs.find_inode_idx(u'/env/test.txt')]
    # f.write(u"Hello world! " * 100)
    # print f.read()
    # print fs.create(u'/usr/manifest.ini', u'-')
    # f = fs.find_inode(u'/usr/manifest.ini')
    # f.delete()
    fs = FileSystem()
    # print fs.create(u'/usr', u'd')
    # print fs.create(u'/env', u'd')
    # print fs.create(u'/env/test.txt', u'-')
    # f = fs.inode_list[fs.find_inode_idx(u'/env/test.txt')]
    # f.write(u"Hello world! " * 100)
    # fs.copy(u'/env/test.txt', u'/usr/test_cp.txt')
    # fs.create(u'/var/www/index.html', u'-')
    # f = fs.find_inode(u'/var')
    # f.delete()
    fs.save()