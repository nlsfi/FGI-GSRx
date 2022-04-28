import torch as t
import torch.nn as nn
import matplotlib.pyplot as plt
import numpy as np
import torch.utils.data as Data
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler,MinMaxScaler
from sklearn.metrics import accuracy_score
from scipy.io import loadmat
import pandas as pd

m = loadmat("D:\下载\datasets\dtexbat.mat")
df = pd.DataFrame(m['dteaxbat'])
X=df.iloc[:,0:10].values #0-9特征
y=df.iloc[:,-1].values
print(X) #特征
print("label:",y)  #最后一列为标签0、1.  1为正常数据


X_train,X_test,y_train,y_test=train_test_split(X,y,test_size=0.25,random_state=123);

#对数据进行标准化处理
scales=MinMaxScaler(feature_range=(0,1)) #将数据集每个特征取值范围转化到0-1之间
X_train_s=scales.fit_transform(X_train)#;print(X_train_s)
X_test_s=scales.transform(X_test)#;print(X_test_s)


class MLP(nn.Module):
    def __init__(self):
        super(MLP, self).__init__()
        self.hidden1=nn.Sequential(
            nn.Linear(10,6,bias=True),
            nn.ReLU()
        )
        self.hidden2 = nn.Sequential(
            nn.Linear(6, 4,bias=True),
            nn.ReLU()
        )

        self.classifica=nn.Sequential(
            nn.Linear(4,2),
            nn.Sigmoid()    #0,1分类激活效果好
        )

    def forward(self,x):
        fc1=self.hidden1(x)
        fc2=self.hidden2(fc1)
        output=self.classifica(fc2)
        return fc1,fc2,output

mynet=MLP()



##训练
X_train_t=t.from_numpy(X_train_s.astype(np.float32))
y_train_t=t.from_numpy(y_train.astype(np.int64))
X_test_t=t.from_numpy(X_test_s.astype(np.float32))
y_test_t=t.from_numpy(y_test.astype(np.int64))
traindata=Data.TensorDataset(X_train_t,y_train_t)
trainloader=Data.DataLoader(
    dataset=traindata,
    batch_size=64,
    shuffle=True,
)


opt=t.optim.Adam(mynet.parameters(),lr=0.01)
lossfun=nn.CrossEntropyLoss()
allloss=[]
acc=[]

for j in range(15):
    train_loss =0
    for step,(b_x,b_y) in enumerate(trainloader):

        _,_,output=mynet(b_x)
        loss=lossfun(output,b_y)

        opt.zero_grad()
        loss.backward()
        opt.step()

        train_loss += loss.item()

        #测试
        _, _, output = mynet(X_test_t)   #output
        _,pre_lab=t.max(output,1)   #dim=1代表行最大
        acc1=accuracy_score(y_test_t,pre_lab)
        acc.append(acc1)

    allloss.append(train_loss)


plt.plot(allloss, label='loss for every epoch')
plt.legend()
plt.show()
plt.plot(acc, label='accuracy for every epoch')
plt.legend()
plt.show()

