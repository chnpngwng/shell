import os
import shutil

# 将YOUR_TARGET_STRING替换为要删除的指定字符
TARGET_STRING = ""

# 获取当前目录及其子目录下的文件列表
for root, dirs, files in os.walk("."):
    for file_name in files:
        file_path = os.path.join(root, file_name)

        # 对文件名进行替换
        new_file_name = file_name.replace(TARGET_STRING, "")
        if new_file_name != file_name:
            new_file_path = os.path.join(root, new_file_name)
            shutil.move(file_path, new_file_path)
            print(f"Renamed: {file_path} -> {new_file_path}")

print("Done!")
