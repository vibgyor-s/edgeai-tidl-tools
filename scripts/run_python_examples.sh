#!/bin/bash
CURDIR=`pwd`
arch=$(uname -p)
if [[ $arch == x86_64 ]]; then
    echo "X64 Architecture"
elif [[ $arch == aarch64 ]]; then
    echo "ARM Architecture"
else
echo 'Processor Architecture must be x86_64 or aarch64'
echo 'Processor Architecture "'$arch'" is Not Supported '
return
fi

if [ -z "$DEVICE" ];then
    echo "DEVICE not defined. Run either of below commands"
    echo "export DEVICE=j7"
    echo "export DEVICE=am62"
    return
else 
    if [ $DEVICE != j7 ] && [ $DEVICE != am62 ]; then
        echo "DEVICE shell var not set correctly. Set"
        echo "export DEVICE=j7"
        echo "export DEVICE=am62"
        return
    fi
fi

if [[ $DEVICE == j7 ]]; then
    cd $CURDIR/examples/osrt_python/tfl
    if [[ $arch == x86_64 ]]; then
    python3 tflrt_delegate.py -c
    fi
    python3 tflrt_delegate.py
    cd $CURDIR/examples/osrt_python/ort
    if [[ $arch == x86_64 ]]; then
    python3 onnxrt_ep.py -c
    fi
    python3 onnxrt_ep.py
    cd $CURDIR/examples/osrt_python/tvm_dlr
    if [[ $arch == x86_64 ]]; then
    python3  tvm_compilation_onnx_example.py --pc-inference
    python3  tvm_compilation_tflite_example.py --pc-inference
    python3  tvm_compilation_onnx_example.py
    python3  tvm_compilation_tflite_example.py
    python3  tvm_compilation_mxnet_example.py
    fi
    python3  dlr_inference_example.py 
    cd $CURDIR
elif [[ $DEVICE == am62 ]]; then
    cd $CURDIR/examples/osrt_python/tfl
    python3 tflrt_delegate.py
    cd $CURDIR/examples/osrt_python/ort
    python3 onnxrt_ep.py 
    cd $CURDIR
fi





