import torch
import torch.nn as nn

from collections.abc import Callable
class ModelFPKMDummy(nn.Module):
    def __init__(self, nfilters_conv1: int = 5, kernel_size_1: int = 3, input_length: int = 1000) -> None:
        super(ModelFPKMDummy, self).__init__()
        
        
        self.conv1 = nn.Sequential(
                        nn.Conv1d(in_channels = 4, out_channels= nfilters_conv1, kernel_size = kernel_size_1),
                        nn.BatchNorm1d(nfilters_conv1),
                        nn.ELU()
                    )
        self.flatten = nn.Flatten()
        
        output_length = input_length - kernel_size_1 + 1
        self.linear = nn.Sequential(
                            nn.Linear(13780, 1), 
                            nn.Softplus()
                    )
        self.relu = nn.ReLU()
        self.softmax = nn.Softmax(dim=1)

    def forward(self, sequence: torch.Tensor):
        x = sequence.permute(0, 2, 1).to(torch.float32)  # permute the two last dimensions of hello 
        x = self.conv1(x)
        x = self.flatten(x)
        print(x.shape)
        x = self.linear(x)
        x = self.relu(x)
        x = self.softmax(x)
        x = x.squeeze()        
        return x
    
    def compute_loss(self, loss_fn, output, fpkm):
        return loss_fn(output, fpkm)
    
    def batch(self, x: dict, y: dict, loss_fn: Callable, optimizer: Callable):

        output = self.forward(**x)
        loss = self.compute_loss(loss_fn, output, **y)
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        return loss # return the main batch loss, later used for computing the validation