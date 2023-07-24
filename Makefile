.PHONY: all install install-rye download-pre-trained-models preprocess-demo-video test-demo-video help

all: help

install: install-rye ## Install all packages
	rye sync

install-rye: ## Install Rye
	curl -sSf https://rye-up.com/get | RYE_NO_AUTO_INSTALL=1 RYE_INSTALL_OPTION="--yes" bash

download-pre-trained-models: ## Download pretrained models
	mkdir -p ./pretrained_models
	(cd pretrained_models && \
		wget http://dl.fbaipublicfiles.com/VisualVoice/av-speech-separation-model/facial_best.pth && \
		wget http://dl.fbaipublicfiles.com/VisualVoice/av-speech-separation-model/lipreading_best.pth && \
		wget http://dl.fbaipublicfiles.com/VisualVoice/av-speech-separation-model/unet_best.pth && \
		wget http://dl.fbaipublicfiles.com/VisualVoice/av-speech-separation-model/vocal_best.pth \
	)

preprocess-demo-video: ## Preprocess the demo video
	ffmpeg -i ./test_videos/interview.mp4 -filter:v fps=fps=25 ./test_videos/interview25fps.mp4
	mv ./test_videos/interview25fps.mp4 ./test_videos/interview.mp4
	python ./utils/detectFaces.py --video_input_path ./test_videos/interview.mp4 --output_path ./test_videos/interview/ --number_of_speakers 2 --scalar_face_detection 1.5 --detect_every_N_frame 8
	ffmpeg -i ./test_videos/interview.mp4 -vn -ar 16000 -ac 1 -ab 192k -f wav ./test_videos/interview/interview.wav
	python ./utils/crop_mouth_from_video.py --video-direc ./test_videos/interview/faces/ --landmark-direc ./test_videos/interview/landmark/ --save-direc ./test_videos/interview/mouthroi/ --convert-gray --filename-path ./test_videos/interview/filename_input/interview.csv

test-demo-video: ## Test with the demo video
	python testRealVideo.py \
		--mouthroi_root ./test_videos/interview/mouthroi/ \
		--facetrack_root ./test_videos/interview/faces/ \
		--audio_path ./test_videos/interview/interview.wav \
		--weights_lipreadingnet pretrained_models/lipreading_best.pth \
		--weights_facial pretrained_models/facial_best.pth \
		--weights_unet pretrained_models/unet_best.pth \
		--weights_vocal pretrained_models/vocal_best.pth \
		--lipreading_config_path configs/lrw_snv1x_tcn2x.json \
		--num_frames 64 \
		--audio_length 2.55 \
		--hop_size 160 \
		--window_size 400 \
		--n_fft 512 \
		--unet_output_nc 2 \
		--normalization \
		--visual_feature_type both \
		--identity_feature_dim 128 \
		--audioVisual_feature_dim 1152 \
		--visual_pool maxpool \
		--audio_pool maxpool \
		--compression_type none \
		--reliable_face \
		--audio_normalization \
		--desired_rms 0.7 \
		--number_of_speakers 2 \
		--mask_clip_threshold 5 \
		--hop_length 2.55 \
		--lipreading_extract_feature \
		--number_of_identity_frames 1 \
		--output_dir_root ./test_videos/interview/

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

