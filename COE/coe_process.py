#!/usr/bin/python3

import sys

def main():
    if len(sys.argv) != 2:
        print("Enter only the filename.")
        exit(2)
    name = sys.argv[1]
    with open(name, "r+") as _f:
        _fl = [open(name.rstrip('.coe')+"_"+str(i)+'.coe', "w+") for i in range(4)]
        l1 = _f.readline()
        l2 = _f.readline()
        for file in _fl:
            file.write(l1+l2)
        while True:
            line = _f.readline()
            if line == '' or line == ';':
                break
            enc = line.split(',')
            for code in enc:
                if code == '' or code == '\n':
                    continue
                _fl[3].write(code[:2]+',')
                _fl[2].write(code[2:4]+',')
                _fl[1].write(code[4:6]+',')
                _fl[0].write(code[6:]+',')
            _fl[0].write('\n')
            _fl[1].write('\n')
            _fl[2].write('\n')
            _fl[3].write('\n')
        for file in _fl:
            file.close()
        _f.close()

if __name__ == "__main__":
    main()