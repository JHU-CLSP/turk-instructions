#!/bin/bash
#
#SBATCH --job-name=i_can_sleep
#SBATCH --output=out.i_can_sleep.log
#SBATCH --error=err.i_can_sleep.log
#
# Number of tasks needed for this job. Generally, used with MPI jobs
#SBATCH --ntasks=1
#SBATCH --partition=parallel
#
# Time format = HH:MM:SS, DD-HH:MM:SS
#SBATCH --time=72:00:00
#
# Minimum memory required per allocated  CPU  in  MegaBytes.
#SBATCH --mem-per-cpu=48000
#SBATCH --cpus-per-task=1
#SBATCH --gres=gpu:1
#SBATCH -A ia1
#SBATCH --partition debug
#SBATCH --qos=normal
#
# Send mail to the email address when the job fails
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=kxu39@jhu.edu

# Load necessary modules
module load anaconda

source ~/.bashrc

conda init
conda activate turk

module list

# Run the Python script
bash="/bin/bash"

python --version
which python

cd turk-instructions/src

run_llava_group() {
    ollama_model=$1
    run_idx=$2
    output_file_0="${run_idx}_${ollama_model}_0.txt"

    echo "Running command group for $ollama_model, iteration $run_idx"

    # Start ollama run in the background and get its PID
    ollama run "$ollama_model" &
    ollama_pid=$!

    # Start the website script in the background and get its PID
    ./1_ia1_run_website.sh &
    website_pid=$!

    # Sleep for some time
    sleep 10

    # 0 relevant_html
    while true; do
        if python3 4_run_evaluation.py --solver_type text-vision --ollama_model "$ollama_model" --tasks test_easy --max_instance_count 4 --num_demonstrations 0 --use_relevant_html --headless --do_eval --server > "$output_file_0" 2>&1; then
            echo "Evaluation for $ollama_model, 0_relevant_html iteration $run_idx completed successfully."
            break
        else
            echo "Evaluation for $ollama_model, 0_relevant html iteration $run_idx failed. Retrying..." | tee -a "$output_file"
            sleep 5  # Wait for 5 seconds before retrying
        fi
    done

    # Kill the ollama run and website processes
    kill $ollama_pid
    kill $website_pid
}

run_command_group() {
    ollama_model=$1
    run_idx=$2
    output_file_3="${run_idx}_${ollama_model}_3.txt"
    output_file_0="${run_idx}_${ollama_model}_0.txt"

    echo "Running command group for $ollama_model, iteration $run_idx"

    # Start ollama run in the background and get its PID
    ollama run "$ollama_model" &
    ollama_pid=$!

    # Start the website script in the background and get its PID
    ./1_ia1_run_website.sh &
    website_pid=$!

    # Sleep for some time
    sleep 10

    # 3 relevant_html
    while true; do
        if python3 4_run_evaluation.py --solver_type text --ollama_model "$ollama_model" --tasks test_easy --max_instance_count 4 --num_demonstrations 3 --use_relevant_html --headless --do_eval --server > "$output_file_3" 2>&1; then
            echo "Evaluation for $ollama_model, 3_relevant_html iteration $run_idx completed successfully."
            break
        else
            echo "Evaluation for $ollama_model, 3_relevant html iteration $run_idx failed. Retrying..." | tee -a "$output_file"
            sleep 5  # Wait for 5 seconds before retrying
        fi
    done

    # 0 full_html
    while true; do
        if python3 4_run_evaluation.py --solver_type text --ollama_model "$ollama_model" --tasks test_easy --max_instance_count 4 --num_demonstrations 0 --no-use_relevant_html --headless --do_eval --server > "$output_file_0" 2>&1; then
            echo "Evaluation for $ollama_model, 0 full_html iteration $run_idx completed successfully."
            break
        else
            echo "Evaluation for $ollama_model, 0 full_html iteration $run_idx failed. Retrying..." | tee -a "$output_file"
            sleep 5  # Wait for 5 seconds before retrying
        fi
    done

    # Kill the ollama run and website processes
    kill $ollama_pid
    kill $website_pid
}

# Main loop to run all command groups 5 times
for run_idx in {1..5}; do
    echo "Starting iteration $run_idx of 5"
    run_llava_group "llava:7b" $run_idx
    run_llava_group "llava:13b" $run_idx
    run_llava_group "llava:34b" $run_idx

    run_command_group "llama2:7b" $run_idx
    run_command_group "llama2:7b-chat" $run_idx
    run_command_group "llama2:13b" $run_idx
    run_command_group "llama2:13b-chat" $run_idx
    run_command_group "llama2:70b" $run_idx
    run_command_group "llama2:70b-chat" $run_idx

    run_llava_group "bakllava" $run_idx
done

echo "All iterations completed."