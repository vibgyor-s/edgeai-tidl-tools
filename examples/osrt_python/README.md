# Python Examples

- [Python Examples](#python-examples)
  - [Introduction](#introduction)
  - [OSRT based user work flow](#osrt-based-user-work-flow)
  - [Model Compilation on PC](#model-compilation-on-pc)
  - [Model Inference on EVM](#model-inference-on-evm)
  - [User options for TFLite and ONNX Runtime](#user-options-for-tflite-and-onnx-runtime)
    - [Required](#required)
    - [Optional](#optional)
  - [User options for TVM](#user-options-for-tvm)
  - [Trouble Shooting](#trouble-shooting)


## Introduction 

TIDL provides multiple deployment options with industry defined inference engines as listed below. These inference engines are being referred as Open Source Run Times  in this document.
* **TFLite Runtime**: [TensorFlow Lite](https://www.tensorflow.org/lite/guide/inference) based inference with heterogeneous execution on cortex-A** + C7x-MMA, using TFlite Delegates [TFLite Delgate](https://www.tensorflow.org/lite/performance/delegates) API
* **ONNX RunTime**: [ONNX Runtime]( https://www.onnxruntime.ai/) based inference with heterogeneous execution on cortex-A** + C7x-MMA.
* **TVM/Neo-AI RunTime**: [TVM]( https://tvm.apache.org)/[Neo-AI-DLR]( https://github.com/neo-ai/neo-ai-dlr) based inference with heterogeneous execution on cortex-A** + C7x-MMA


>** *TDA4VM has cortex-A72 as its MPU, refer to the device TRM to know which cortex-A MPU* it contains.

These heterogeneous execution enables:
1. OSRT as the top level inference API for user applications
2. Offloading subgraphs to C7x/MMA for accelerated execution with TIDL
3. Runs optimized code on ARM core for layers that are not supported by TIDL


## OSRT based user work flow 

The diagram below illustrates the TFLite based work flow as an example. ONNX RunTime and TVM/Neo-AI RunTime also follows similar work flow. The User needs to run the model compilation (sub-graph(s) creation and quantization) on PC and the generated artifacts can be used for inference on the device.

![TFLite runtime based user work flow](../../docs/tflrt_work_flow.png)

## Model Compilation on PC

![OSRT Compile Steps](../../docs/osrt_compile_steps.png)

1. Prepare the Environment for the Model compilation by follwoing the setup section [here](../../README.md#setup)

2. Run for model compilation in the corresponding example folder  – This step generates artifacts needed for inference in the \<repo base>\/model-artifacts folder. Each subgraph is identified in the artifacts using the tensor index of its output in the model	
```
cd examples/osrt_python/tfl
python3 tflrt_delegate.py -c
```
3.	Run Inference on PC	- Optionally user can test the inference in host emulation mode and check the output; the output images will be saved in the corresponding specified artifacts folder
```
python3 tflrt_delegate.py
```
4. Run Inference on PC without offload -  Optionally user can test the inference in host emulation mode without using any delegation to TI Delegate
```
python3 tflrt_delegate.py -d
```


## Model Inference on EVM

The artifacts generated by python scripts in the above section can be inferred using either python or C/C++ APIs. The following steps are for running inference using python API.

![OSRT Run Steps](../../docs/osrt_run_steps.png)

1.	Copy the below folders from PC to the EVM where this repo is cloned
```
./model-artifacts
./models
```
2. Run the inference script in the corresponding example folder on the EVM and check the results, performance etc.
```
cd examples/osrt_python/tfl
python3 tflrt_delegate.py
```

Note : These scripts are only for basic functionally testing and performance check. Accuracy of the models can be benchmarked using the python module released here [edgeai-benchmark](https://github.com/TexasInstruments/edgeai-benchmark)


## User options for TFLite and ONNX Runtime

An example call to TFLite interpreter from the python interface using delegate mechanism:
    
    interpreter = tflite.Interpreter(model_path='path_to_model', \
                        experimental_delegates=[tflite.load_delegate('libtidl_tfl_delegate.so.1.0', delegate_options)])

An example call to ONNX runtime session from the python interface :
    
    EP_list = ['TIDLExecutionProvider','CPUExecutionProvider']
    sess = rt.InferenceSession('path_to_model' ,providers=EP_list, provider_options=[delegate_options, {}], sess_options=so)

'delegate_options' in the inference session call comprise of the following options (required and optional). All these options are common for TFLite and ONNX runtime.


### Required 

The following options need to be specified by user while creating TFLite interpreter:

|       Name         | Value                                                   |
|:-------------------|:--------------------------------------------------------|
| tidl_tools_path    | to be set to ${TIDL_TOOLS_PATH} - Path from where to pick TIDL related tools |
| artifacts_folder   | folder where user intends to store all the compilation artifacts |

### Optional

The following options are set to default values, to be specified if modification needed by user. Below optional arguments are specific to model compilation and not applicable to inference except the 'debug_level'

|       Name         |                      Description                        |        Default values      |
|:-------------------|:--------------------------------------------------------|:--------------------------:|
| platform           | "J7"                                                    | "J7"                       |
| version            | TIDL version - open source runtimes supported from version 7.2 onwards       | (7,3)                      |
| tensor_bits        | Number of bits for TIDL tensor and weights - 8/16       | 8                          |
| debug_level        | 0 - no debug, 1 - rt debug prints, >=2 - increasing levels of debug and trace dump | 0                          |
| max_num_subgraphs  | offload up to \<num\> tidl subgraphs                    | 16                         |                  
| deny_list          | force disable offload of a particular operator to TIDL [^2] | ""  - Empty list       |
| accuracy_level     | 0 - basic calibration, 1 - higher accuracy(advanced bias calibration), 9 - user defined [^3] | 1                    | 
| advanced_options:calibration_frames              | Number of frames to be used for calibration - min 10 frames recommended | 20                 |
| advanced_options:calibration_iterations          | Number of bias calibration iterations                               | 50                 |
| advanced_options:output_feature_16bit_names_list | List of names of the layers (comma separated string) as in the original model whose feature/activation output user wants to be in 16 bit  [^4] | ""            |
| advanced_options:params_16bit_names_list         | List of names of the output layers (separated by comma or space or tab) as in the original model whose parameters user wants to be in 16 bit  [^1] | ""            |
| advanced_options:quantization_scale_type         | 0 for non-power-of-2, 1 for power-of-2                                  | 0                  |
| advanced_options:high_resolution_optimization    | 0 for disable, 1 for enable                                             | 0                  |
| advanced_options:pre_batchnorm_fold              | Fold batchnorm layer into following convolution layer, 0 for disable, 1 for enable | 1       |
| advanced_options:add_data_convert_ops            | Adds the Input and Output format conversions to Model and performs the same in DSP instead of ARM. This is currently a experimental feature.                |    0                  |
| object_detection:confidence_threshold            | Override "nms_score_threshold" parameter threshold in tflite detection post processing layer | Read from model |
| object_detection:nms_threshold                   | Override "nms_iou_threshold" parameter threshold in tflite detection post processing layer   | Read from model |
| object_detection:top_k                           | Override "detections_per_class" parameter threshold in tflite detection post processing layer| Read from model |
| object_detection:keep_top_k                      | Override "max_detections" parameter threshold in tflite detection post processing layer      | Read from model |
| ti_internal_nc_flag                              | internal use only                                                                            | -               |

Below options will be overwritten only if accuracy_level = 9, else will be discarded. For accuracy level 9, specified options will be overwritten, rest will be set to default values. For accuracy_level = 0/1, these are preset internally.

|                    Name                    |                      Description                        |        Default values      |
|:-------------------------------------------|:--------------------------------------------------------|:--------------------------:|
|advanced_options:activation_clipping        | 0 for disable, 1 for enable                       | 1                          |
|advanced_options:weight_clipping            | 0 for disable, 1 for enable                       | 1                          |
|advanced_options:bias_calibration           | 0 for disable, 1 for enable                       | 1                          |
|advanced_options:channel_wise_quantization  | 0 for disable, 1 for enable                       | 0                          |

- [^1]: This is not the name of the parameter of the layer but is expected to be the output name of the layer. Note that, if a given layers feature/activations is in 16 bit then parameters will automatically become 16 bit even if its not part of this list  \n- [^2]: Denylist is a string of comma separated numbers which represent the operators as identified in tflite builtin ops. Please refer [Tflite builtin ops](https://github.com/tensorflow/tensorflow/blob/r2.3/tensorflow/lite/builtin_ops.h)  , e.g. deny_list = "1, 2" to deny offloading 'AveragePool2d' and 'Concatenation' operators to TIDL. \n
- [^3]: Advanced calibration options can be specified by setting accuracy_level = 9. \n
- [^4]: Note that if for a given layer feature/activations is in 16 bit then parameters will automatically become 16 bit and user need not specify them as part of "advanced_options:params_16bit_names_list". Example format - "conv1_2, fire9/concat_1" \n


## User options for TVM

There are only 4 lines that are specific to TIDL offload in TVM+TIDL compilation scripts.
The rest of the script is no different from a regular TVM compilation
script without TIDL offload.

    tidl_compiler = tidl.TIDLCompiler(platform="J7", version="7.3",
                                      tidl_tools_path=get_tidl_tools_path(),
                                      artifacts_folder=tidl_artifacts_folder,
                                      tensor_bits=8,
                                      max_num_subgraphs=max_num_subgraphs,
                                      deny_list=args.denylist,
                                      accuracy_level=1,
                                      advanced_options={'calibration_iterations':10}
                                     )

We first instantiate a TIDLCompiler object.  The parameters are explained
in the following table.

| Name/Position      | Value                                                   |
|:-------------------|:--------------------------------------------------------|
| platform           | "J7"                                                 |
| version            | "7.3"                                                   |
| tidl_tools_path    | set to environment variable TIDL_TOOLS_PATH, usually psdk_rtos_install/tidl_xx_yy_zz_ww/ti_dl/tidl_tools |
| artifacts_folder   | where to store deployable module                        |
| **Optional Parameters** |                                                    |
| tensor_bits        | 8 or 16 for import TIDL tensor and weights, default is 8|
| debug_level        | 0, 1, 2, 3, 4 for various debug info, default is 0      |
| max_num_subgraphs  | offload up to \<num\> tidl subgraphs, default is 16     |
| deny_list          | deny TVM relay ops for TIDL offloading, comma separated string, default is "" |
| accuracy_level     | 0 for simple calibration, 1 for advanced bias calibration, 9 for user defined, default is 1 |
| ti_internal_nc_flag| internal use only , default is 0x641                    |
| advanced_options   | a dictionary to overwrite default calibration options, default is {} |
| **advanced_options Keys** | (if not specified, defaults are used)            |
| 'calibration_iterations'  | number of calibration iterations , default is 50 |
| 'quantization_scale_type' | 0 for non-power-of-2, 1 for power-of-2, default is 0 |
| 'high_resolution_optimization' | 0 for disable, 1 for enable, default is 0   |
| 'pre_batchnorm_fold'      | 0 for disable, 1 for enable, default is 1        |
| 'output_feature_16bit_names_list' | comma separated string, default is ""    |
| 'params_16bit_names_list'         | comma separated string, default is ""    |
|                           | (below are overwritable at accuracy level 9 only)|
| 'activation_clipping'     | 0 for disable, 1 for enable                      |
| 'weight_clipping'         | 0 for disable, 1 for enable                      |
| 'bias_calibration'        | 0 for disable, 1 for enable                      |
| 'channel_wise_quantization' | 0 for disable, 1 for enable                    |


## Trouble Shooting
Refre this [Troubel Shooting](../../docs/tidl_osr_debug.md) section if any issues observed during compialtion of custom models