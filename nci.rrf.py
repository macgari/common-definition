import sys


class proc():
    def __init__(self, source=None):
        self._source = source
        self._mrxw_eng = 'MRXW_ENG'
        self._mrxw = 'MRXW'
        self._block_term = ';'

    @staticmethod
    def source_lines(source):
        with open(source, 'r') as sl:
            return [line.strip() for line in sl if line is not None]

    @staticmethod
    def save_lines(dest, lines):
        with open(dest, 'w') as dest:
            for line in lines:
                dest.write(line)

    def handle_mrxw(self, source_lines):
        blocks = []
        block = ''
        for line in source_lines:
            block = block + '\n' + line

            if block.endswith(self._block_term) and (self._mrxw_eng in block or self._mrxw not in block):
                blocks.append(block)
                block = ''

            elif block.endswith(self._block_term):
                block = ''

        return blocks


if __name__ == '__main__':
    file = sys.argv[1]
    proc = proc()
    source_lines = proc.source_lines(file)
    lines = proc.handle_mrxw(source_lines)
    proc.save_lines(file, lines)
