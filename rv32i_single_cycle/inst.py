ans = [""]
def inst():
    x = input()
    if x == "":
        return 0
    ans[0] = ans[0] + 'X"'+x[6:8]+'", X"'+x[4:6]+'", X"'+x[2:4]+'", X"'+x[0:2]+'",'+"\n"
    inst()


inst()
print(ans[0])
