#!/bin/bash

arch=mbart_large
exp_name=${1:-fusion}
adapter_dir=$2
adapter_size=$3
pretrained_model=$4
src=$5
tgt=$6
hparams=${@:7}

NMT_DIR=<path to working folder>
SAVE_DIR=$NMT_DIR/models/$exp_name
data_dir=$NMT_DIR/data-bin
mkdir -p $SAVE_DIR
chmod  a+w $SAVE_DIR

LANGS='cs,de,en,es_XX,et_EE,fi_FI,fr_XX,gu_IN,hi_IN,it_IT,kk_KZ,ko_KR,lt_LT,lv_LV,my_MM,ne_NP,nl_XX,ro_RO,ru_RU,si,tr_TR'
ARCH=domain_adapter_mbart_large
TASK=translation_multilingual_multidomain
CRITERION=label_smoothed_cross_entropy
DOMAINS="it,law,koran,medical,subtitles"
TOK_SCRIPT="${NMT_DIR}/lodo-nmt/m2m_100/tok.sh"
MODEL_DICT=$NMT_DIR/models/mbart.cc25/dict.txt
pretrained_model=$NMT_DIR/models/mbart.cc25/model.pt
tool=$NMT_DIR/lodo-nmt/fairseq/train.py
decode_tool=$NMT_DIR/lodo-nmt/fairseq/fairseq_cli/generate.py

python $tool $data_dir \
  --save-dir $SAVE_DIR \
  --pretrained-nmt $pretrained_model \
  --user-dir $NMT_DIR/lodo-nmt/mdml-nmt \
  --encoder-normalize-before --decoder-normalize-before \
  --arch $ARCH \
  --task $TASK \
  --sampling-method "temperature" \
  --sampling-temperature 5 \
  --encoder-langtok "tgt" \
  --langs $LANGS --lang-pairs "${src}-${tgt}" \
  --domains $DOMAINS \
  --criterion $CRITERION --label-smoothing 0.2 \
  --optimizer adam --adam-eps 1e-06 --adam-betas '(0.9, 0.98)' \
  --lr-scheduler inverse_sqrt --lr 5e-5 --warmup-updates 10000 --max-update 200000 --patience 5 \
  --dropout 0.3 --attention-dropout 0.1 --weight-decay 0.0 \
  --max-tokens 1024 --update-freq 2  \
  --save-interval 1 --save-interval-updates 5000 --keep-interval-updates 1 --no-epoch-checkpoints \
  --log-format simple  \
  --reset-optimizer --reset-meters --reset-dataloader --reset-lr-scheduler \
  --share-decoder-input-output-embed \
  --share-all-embeddings --ddp-backend no_c10d \
  --tensorboard-logdir $SAVE_DIR/log --amp --num-workers 8 \
  --down-sample ${adapter_size}  \
  --freeze-encoder --freeze-decoder --decoder-adapter --encoder-adapter \
  --adapter-dir $adapter_dir --fusion --clip-norm 1.0 \
  $hparams