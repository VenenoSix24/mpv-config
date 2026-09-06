### AI超分（真人）— W2xEX Photo Small，DX12显卡专用
### 由 MIX_UAI_DML.vpy 复制修改，仅换了模型；参数说明见原文件

import vapoursynth as vs
from vapoursynth import core
import k7sfunc as k7f

core.num_threads = k7f.vs_t_dft
clip = video_in

############
# 用户选项 #
############

H_Pre = 540
Model = "hongyuanyu_span_ch48_x2_fp16_op17.onnx"
Fp16_Qnt = True
Gpu = 0
Gpu_T = 2
H_Max = 1080
Lk_Fmt = False

ret = k7f.FMT_CTRL(clip, h_max=1200, h_ret=True)
clip = k7f.FMT_CTRL(clip, h_max=H_Pre, fmt_pix=1 if Lk_Fmt else 0)
clip = k7f.UAI_DML(clip, crc=False, model_pth=Model, fp16_qnt=Fp16_Qnt, gpu=Gpu, gpu_t=Gpu_T)
clip = k7f.FMT_CTRL(clip, h_max=H_Max, fmt_pix=1 if Lk_Fmt else 0)

clip.set_output()
